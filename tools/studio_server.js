#!/usr/bin/env node
/**
 * 念佛計數器 - 佛曲整合工作站本地 FFmpeg 橋接服務
 * 零外部套件依賴 (僅使用 Node.js 內建模組)，提供：
 * 1. 靜態伺服 tools/marker_recorder.html (http://127.0.0.1:8765)
 * 2. 支援 file:// 直接開啟網頁時的跨來源連線 (CORS)
 * 3. 呼叫系統原生 ffmpeg / ffprobe 執行精準剪輯、轉檔 (.ogg/.mp3/.m4a/.wav)、loudnorm 響度標準化與清除亂碼 Metadata
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawn } = require('child_process');

const PORT = Number(process.env.PORT) || 8765;
const HOST = '127.0.0.1';

const TOOLS_DIR = __dirname;
const PROJECT_ROOT = path.resolve(TOOLS_DIR, '..');
const AUDIO_DIR = path.join(PROJECT_ROOT, 'assets', 'audio');
const EDIT_DIR = path.join(AUDIO_DIR, 'edit');
const TEMP_DIR = path.join(os.tmpdir(), 'buddha_counter_studio');

fs.mkdirSync(TEMP_DIR, { recursive: true });

const tempFiles = new Map(); // id -> { filePath, filename, createdAt }

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Filename');
  res.setHeader('Access-Control-Allow-Private-Network', 'true');
}

function sendJson(res, statusCode, payload) {
  setCorsHeaders(res);
  res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(payload));
}

function getMimeType(ext) {
  switch (ext.toLowerCase()) {
    case '.ogg': return 'audio/ogg';
    case '.mp3': return 'audio/mpeg';
    case '.m4a': return 'audio/mp4';
    case '.aac': return 'audio/aac';
    case '.wav': return 'audio/wav';
    case '.flac': return 'audio/flac';
    default: return 'application/octet-stream';
  }
}

function sanitizeFilename(name) {
  const base = path.basename(String(name || 'output.ogg')).trim();
  return base.replace(/[<>:"/\\|?*\x00-\x1F]/g, '_') || 'output.ogg';
}

function resolveProjectAudioFile(dirType, filename) {
  const baseDir = dirType === 'audio' ? AUDIO_DIR : EDIT_DIR;
  const safeName = path.basename(String(filename || ''));
  if (!safeName) return null;
  const fullPath = path.resolve(baseDir, safeName);
  if (!fullPath.startsWith(path.resolve(baseDir) + path.sep)) {
    return null;
  }
  return fullPath;
}

function findWinGetFfmpegBin(exeName) {
  const localAppData = process.env.LOCALAPPDATA || '';
  if (!localAppData) return null;

  const linkCandidate = path.join(localAppData, 'Microsoft', 'WinGet', 'Links', exeName);
  if (fs.existsSync(linkCandidate)) return linkCandidate;

  const pkgRoot = path.join(localAppData, 'Microsoft', 'WinGet', 'Packages');
  if (fs.existsSync(pkgRoot)) {
    for (const pkg of fs.readdirSync(pkgRoot)) {
      if (!/ffmpeg/i.test(pkg)) continue;
      const pkgDir = path.join(pkgRoot, pkg);
      try {
        for (const sub of fs.readdirSync(pkgDir)) {
          const binCandidate = path.join(pkgDir, sub, 'bin', exeName);
          if (fs.existsSync(binCandidate)) return binCandidate;
        }
      } catch (_) {}
    }
  }
  return null;
}

const resolvedBins = {};
function resolveMediaBin(cmd) {
  if (resolvedBins[cmd]) return resolvedBins[cmd];
  if (process.platform === 'win32' && (cmd === 'ffmpeg' || cmd === 'ffprobe')) {
    const found = findWinGetFfmpegBin(`${cmd}.exe`);
    if (found) {
      resolvedBins[cmd] = found;
      return found;
    }
  }
  resolvedBins[cmd] = cmd;
  return cmd;
}

function runCommandCapture(cmd, args) {
  const actualCmd = resolveMediaBin(cmd);
  return new Promise((resolve) => {
    const child = spawn(actualCmd, args, { windowsHide: true });
    const stdoutChunks = [];
    const stderrChunks = [];

    child.stdout.on('data', (chunk) => stdoutChunks.push(chunk));
    child.stderr.on('data', (chunk) => stderrChunks.push(chunk));

    child.on('error', (err) => {
      resolve({
        ok: false,
        code: -1,
        stdout: '',
        stderr: err.message,
      });
    });

    child.on('close', (code) => {
      resolve({
        ok: code === 0,
        code,
        stdout: Buffer.concat(stdoutChunks).toString('utf8'),
        stderr: Buffer.concat(stderrChunks).toString('utf8'),
      });
    });
  });
}

async function runFfprobe(filePath) {
  const res = await runCommandCapture('ffprobe', [
    '-v', 'quiet',
    '-print_format', 'json',
    '-show_format',
    '-show_streams',
    filePath,
  ]);
  if (!res.ok) {
    return null;
  }
  try {
    return JSON.parse(res.stdout);
  } catch (_) {
    return null;
  }
}

function listAudioFilesInDir(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  const allowed = new Set(['.mp3', '.ogg', '.m4a', '.wav', '.flac', '.aac']);
  return fs.readdirSync(dirPath, { withFileTypes: true })
    .filter((d) => d.isFile() && allowed.has(path.extname(d.name).toLowerCase()))
    .map((d) => {
      const stat = fs.statSync(path.join(dirPath, d.name));
      return {
        name: d.name,
        size: stat.size,
        mtimeMs: stat.mtimeMs,
      };
    })
    .sort((a, b) => a.name.localeCompare(b.name, 'zh-Hant-TW', { numeric: true }));
}

function collectRequestBody(req, maxBytes = 150 * 1024 * 1024) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let total = 0;
    req.on('data', (chunk) => {
      total += chunk.length;
      if (total > maxBytes) {
        reject(new Error('檔案超過大小上限 (150MB)'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function streamFile(req, res, filePath, downloadFilename = null) {
  if (!fs.existsSync(filePath)) {
    sendJson(res, 404, { ok: false, error: '找不到指定的音訊檔案' });
    return;
  }
  const stat = fs.statSync(filePath);
  const ext = path.extname(filePath);
  const mime = getMimeType(ext);

  setCorsHeaders(res);
  const headers = {
    'Content-Type': mime,
    'Accept-Ranges': 'bytes',
  };
  if (downloadFilename) {
    const encoded = encodeURIComponent(downloadFilename);
    headers['Content-Disposition'] = `attachment; filename="audio${ext}"; filename*=UTF-8''${encoded}`;
  }

  const range = req.headers.range;
  if (range) {
    const match = /bytes=(\d*)-(\d*)/.exec(range);
    if (match) {
      const start = match[1] ? parseInt(match[1], 10) : 0;
      const end = match[2] ? parseInt(match[2], 10) : stat.size - 1;
      if (start <= end && end < stat.size) {
        headers['Content-Range'] = `bytes ${start}-${end}/${stat.size}`;
        headers['Content-Length'] = end - start + 1;
        res.writeHead(206, headers);
        fs.createReadStream(filePath, { start, end }).pipe(res);
        return;
      }
    }
  }

  headers['Content-Length'] = stat.size;
  res.writeHead(200, headers);
  fs.createReadStream(filePath).pipe(res);
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'OPTIONS') {
      setCorsHeaders(res);
      res.writeHead(204);
      res.end();
      return;
    }

    const parsedUrl = new URL(req.url, `http://${HOST}:${PORT}`);
    const pathname = parsedUrl.pathname;

    // 1. 靜態頁面與圖示
    if (req.method === 'GET' && (pathname === '/' || pathname === '/marker_recorder.html')) {
      const htmlPath = path.join(TOOLS_DIR, 'marker_recorder.html');
      if (!fs.existsSync(htmlPath)) {
        sendJson(res, 404, { ok: false, error: '找不到 marker_recorder.html' });
        return;
      }
      setCorsHeaders(res);
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-cache',
      });
      fs.createReadStream(htmlPath).pipe(res);
      return;
    }

    // 2. 服務狀態與專案音檔清單
    if (req.method === 'GET' && pathname === '/api/status') {
      const ffCheck = await runCommandCapture('ffmpeg', ['-version']);
      const firstLine = ffCheck.ok ? (ffCheck.stdout.split(/\r?\n/)[0] || '') : '';
      sendJson(res, 200, {
        ok: true,
        ffmpegReady: ffCheck.ok,
        ffmpegVersion: firstLine,
        projectRoot: PROJECT_ROOT,
        files: {
          edit: listAudioFilesInDir(EDIT_DIR),
          audio: listAudioFilesInDir(AUDIO_DIR),
        },
      });
      return;
    }

    // 3. 讀取專案目錄下的音訊檔案
    if (req.method === 'GET' && pathname === '/api/project-file') {
      const dirType = parsedUrl.searchParams.get('dir') === 'audio' ? 'audio' : 'edit';
      const name = parsedUrl.searchParams.get('name') || '';
      const fullPath = resolveProjectAudioFile(dirType, name);
      if (!fullPath || !fs.existsSync(fullPath)) {
        sendJson(res, 404, { ok: false, error: '找不到該專案音訊檔' });
        return;
      }
      streamFile(req, res, fullPath);
      return;
    }

    // 4. 對專案目錄下的音訊檔執行 ffprobe
    if (req.method === 'GET' && pathname === '/api/probe-project-file') {
      const dirType = parsedUrl.searchParams.get('dir') === 'audio' ? 'audio' : 'edit';
      const name = parsedUrl.searchParams.get('name') || '';
      const fullPath = resolveProjectAudioFile(dirType, name);
      if (!fullPath || !fs.existsSync(fullPath)) {
        sendJson(res, 404, { ok: false, error: '找不到該專案音訊檔' });
        return;
      }
      const probe = await runFfprobe(fullPath);
      sendJson(res, 200, { ok: true, probe });
      return;
    }

    // 5. 上傳本地檔案至暫存區並執行 ffprobe
    if (req.method === 'POST' && pathname === '/api/upload') {
      const rawName = decodeURIComponent(req.headers['x-filename'] || 'input.mp3');
      const safeName = sanitizeFilename(rawName);
      const ext = path.extname(safeName) || '.mp3';
      const buf = await collectRequestBody(req);
      if (!buf.length) {
        sendJson(res, 400, { ok: false, error: '上傳內容為空' });
        return;
      }
      const tempId = `in_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      const tempPath = path.join(TEMP_DIR, `${tempId}${ext}`);
      fs.writeFileSync(tempPath, buf);
      tempFiles.set(tempId, { filePath: tempPath, filename: safeName, createdAt: Date.now() });

      const probe = await runFfprobe(tempPath);
      sendJson(res, 200, {
        ok: true,
        tempId,
        filename: safeName,
        size: buf.length,
        probe,
      });
      return;
    }

    // 6. 串流或下載暫存輸出檔
    if (req.method === 'GET' && pathname === '/api/temp-file') {
      const id = parsedUrl.searchParams.get('id') || '';
      const dl = parsedUrl.searchParams.get('download') === '1';
      const entry = tempFiles.get(id);
      if (!entry || !fs.existsSync(entry.filePath)) {
        sendJson(res, 404, { ok: false, error: '暫存檔不存在或已過期' });
        return;
      }
      streamFile(req, res, entry.filePath, dl ? entry.filename : null);
      return;
    }

    // 7. 核心 FFmpeg 剪輯 / 轉檔 / 音量 / Metadata 處理
    if (req.method === 'POST' && pathname === '/api/process') {
      const bodyBuf = await collectRequestBody(req, 5 * 1024 * 1024);
      const opts = JSON.parse(bodyBuf.toString('utf8'));

      let inputPath = null;
      if (opts.sourceType === 'project') {
        inputPath = resolveProjectAudioFile(opts.projectDir, opts.projectName);
      } else if (opts.tempId && tempFiles.has(opts.tempId)) {
        inputPath = tempFiles.get(opts.tempId).filePath;
      }

      if (!inputPath || !fs.existsSync(inputPath)) {
        sendJson(res, 400, { ok: false, error: '找不到來源音訊檔案，請重新選擇或載入音檔。' });
        return;
      }

      const inputProbe = await runFfprobe(inputPath);
      const origStream = inputProbe?.streams?.find((s) => s.codec_type === 'audio');
      const origSampleRate = Number(origStream?.sample_rate) || 44100;
      const origDuration = Number(inputProbe?.format?.duration) || 0;

      const mode = opts.mode === 'copy' ? 'copy' : 'encode';
      const format = ['ogg', 'mp3', 'm4a', 'wav'].includes(opts.format) ? opts.format : 'ogg';
      const inputExt = path.extname(inputPath).toLowerCase().replace('.', '');
      const outExt = mode === 'copy' ? (inputExt || format) : format;

      let outName = sanitizeFilename(opts.outputFilename || `output.${outExt}`);
      if (path.extname(outName).toLowerCase() !== `.${outExt}`) {
        const stem = path.basename(outName, path.extname(outName));
        outName = `${stem}.${outExt}`;
      }

      const args = ['-hide_banner'];

      // 計算剪輯時間
      const trimEnabled = Boolean(opts.trimEnabled);
      const trimStart = Math.max(0, Number(opts.trimStart) || 0);
      const trimEnd = Number(opts.trimEnd) || 0;
      let expectedDuration = origDuration;

      if (trimEnabled) {
        if (trimStart > 0) {
          args.push('-ss', trimStart.toFixed(3));
        }
        if (trimEnd > trimStart) {
          args.push('-to', trimEnd.toFixed(3));
          expectedDuration = trimEnd - trimStart;
        } else if (origDuration > trimStart) {
          expectedDuration = origDuration - trimStart;
        }
      }

      args.push('-i', inputPath);

      // 清除所有舊標籤與亂碼
      if (opts.stripMetadata !== false) {
        args.push('-map_metadata', '-1');
      }

      // 僅保留第一條音訊軌 (去除封面圖或雜訊軌避免 ogg 封裝問題)
      args.push('-vn');

      if (mode === 'copy') {
        args.push('-c:a', 'copy');
      } else {
        // 組合音訊濾鏡 (-af)
        const filters = [];
        const volMode = opts.volumeMode || 'none';
        const volVal = Number(opts.volumeValue);

        if (volMode === 'loudnorm') {
          filters.push('loudnorm=I=-16:TP=-1.5:LRA=11');
        } else if (volMode === 'multiplier' && Number.isFinite(volVal) && volVal > 0 && volVal !== 1) {
          filters.push(`volume=${volVal}`);
        } else if (volMode === 'db' && Number.isFinite(volVal) && volVal !== 0) {
          filters.push(`volume=${volVal}dB`);
        }

        const fadeMs = Math.max(0, Number(opts.fadeMs) || 0);
        if (fadeMs > 0 && expectedDuration > (fadeMs * 2.5) / 1000) {
          const fadeSec = (fadeMs / 1000).toFixed(4);
          const fadeOutStart = Math.max(0, expectedDuration - fadeMs / 1000).toFixed(4);
          filters.push(`afade=t=in:st=0:d=${fadeSec}`);
          filters.push(`afade=t=out:st=${fadeOutStart}:d=${fadeSec}`);
        }

        if (filters.length > 0) {
          args.push('-af', filters.join(','));
        }

        // 取樣率控制 (特別防止 loudnorm 自動升頻至 192000Hz)
        const reqSr = String(opts.sampleRate || '44100');
        if (reqSr === '44100' || reqSr === '48000' || reqSr === '32000') {
          args.push('-ar', reqSr);
        } else if (volMode === 'loudnorm') {
          const safeOrigSr = origSampleRate > 48000 ? 44100 : origSampleRate;
          args.push('-ar', String(safeOrigSr));
        }

        // 編碼器設定
        if (format === 'ogg') {
          const q = opts.quality !== undefined ? String(opts.quality) : '5';
          args.push('-c:a', 'libvorbis', '-q:a', q);
        } else if (format === 'mp3') {
          const q = opts.quality !== undefined ? String(opts.quality) : '2';
          args.push('-c:a', 'libmp3lame', '-q:a', q, '-id3v2_version', '3');
        } else if (format === 'm4a') {
          args.push('-c:a', 'aac', '-b:a', '192k');
        } else if (format === 'wav') {
          args.push('-c:a', 'pcm_s16le');
        }
      }

      // 寫入乾淨 UTF-8 Metadata (同時寫入容器與音訊串流層，確保 OGG Vorbis / MP3 / M4A 100% 一致)
      const meta = opts.metadata || {};
      for (const key of ['title', 'artist', 'album']) {
        if (typeof meta[key] === 'string' && meta[key].trim() !== '') {
          const val = meta[key].trim();
          args.push('-metadata', `${key}=${val}`);
          args.push('-metadata:s:a:0', `${key}=${val}`);
        }
      }

      const outTempId = `out_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      const outTempPath = path.join(TEMP_DIR, `${outTempId}.${outExt}`);
      args.push('-y', outTempPath);

      const ffRes = await runCommandCapture('ffmpeg', args);
      if (!ffRes.ok || !fs.existsSync(outTempPath)) {
        sendJson(res, 500, {
          ok: false,
          error: 'FFmpeg 執行失敗',
          log: ffRes.stderr || ffRes.stdout,
          command: `ffmpeg ${args.map((a) => (/\s/.test(a) ? `"${a}"` : a)).join(' ')}`,
        });
        return;
      }

      tempFiles.set(outTempId, {
        filePath: outTempPath,
        filename: outName,
        createdAt: Date.now(),
      });

      let savedRelPath = null;
      let savedFullPath = null;
      if (opts.outputDir === 'edit' || opts.outputDir === 'audio') {
        const targetDir = opts.outputDir === 'audio' ? AUDIO_DIR : EDIT_DIR;
        fs.mkdirSync(targetDir, { recursive: true });
        savedFullPath = path.join(targetDir, outName);
        fs.copyFileSync(outTempPath, savedFullPath);
        savedRelPath = opts.outputDir === 'audio'
          ? `assets/audio/${outName}`
          : `assets/audio/edit/${outName}`;
      }

      const outProbe = await runFfprobe(outTempPath);
      const outStat = fs.statSync(outTempPath);

      sendJson(res, 200, {
        ok: true,
        outTempId,
        outputFilename: outName,
        outputSize: outStat.size,
        savedRelPath,
        savedFullPath,
        probe: outProbe,
        log: ffRes.stderr,
        files: {
          edit: listAudioFilesInDir(EDIT_DIR),
          audio: listAudioFilesInDir(AUDIO_DIR),
        },
      });
      return;
    }

    sendJson(res, 404, { ok: false, error: 'Not Found' });
  } catch (err) {
    sendJson(res, 500, { ok: false, error: err.message || String(err) });
  }
});

server.on('error', (err) => {
  if (err && err.code === 'EADDRINUSE') {
    console.log('==========================================================');
    console.log(`  佛曲整合工作站服務已在執行中: http://${HOST}:${PORT}`);
    console.log('  已為您開啟瀏覽器頁面，此重複視窗可直接關閉。');
    console.log('==========================================================');
    process.exit(0);
  }
  console.error('伺服器啟動錯誤:', err);
  process.exit(1);
});

server.listen(PORT, HOST, () => {
  console.log('==========================================================');
  console.log('  念佛計數器 - 佛曲剪輯・轉檔・Metadata・打點整合工作站');
  console.log(`  請在瀏覽器開啟: http://${HOST}:${PORT}`);
  console.log('  (保持此視窗開啟即可在網頁內一鍵呼叫 FFmpeg 直接轉檔)');
  console.log('==========================================================');
});

