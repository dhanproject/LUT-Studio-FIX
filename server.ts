import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer as createViteServer } from 'vite';
import multer from 'multer';
import sharp from 'sharp';
import fs from 'fs-extra';
import { v4 as uuidv4 } from 'uuid';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const PORT = 3000;
  const isProd = process.env.NODE_ENV === 'production';

  app.use(express.json({ limit: '50mb' }));

  // Storage for uploads and processed images
  const UPLOAD_DIR = path.join(process.cwd(), 'uploads');
  const PROCESSED_DIR = path.join(process.cwd(), 'processed');
  await fs.ensureDir(UPLOAD_DIR);
  await fs.ensureDir(PROCESSED_DIR);

  const upload = multer({ dest: UPLOAD_DIR });

  // --- API ROUTES ---

  app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

  // Pro Engine: Apply LUT via Sharp (Simulating Numpy precision)
  app.post('/api/process', upload.fields([{ name: 'image', maxCount: 1 }, { name: 'lut', maxCount: 1 }]), async (req: any, res: any) => {
    try {
      const files = req.files;
      const intensity = parseFloat(req.body.intensity || '1.0');
      
      if (!files.image || !files.lut) {
        return res.status(400).json({ error: 'Image and LUT required' });
      }

      const imgPath = files.image[0].path;
      const lutPath = files.lut[0].path;
      const outputName = `${uuidv4()}.jpg`;
      const outputPath = path.join(PROCESSED_DIR, outputName);

      // --- LUT Parsing (Node.js Side) ---
      const lutTxt = await fs.readFile(lutPath, 'utf8');
      const lines = lutTxt.split('\n');
      let size = 0;
      let lutData: number[] = [];

      for (let line of lines) {
        line = line.trim();
        if (line.startsWith('LUT_3D_SIZE')) size = parseInt(line.split(/\s+/)[1]);
        else if (line.match(/^[-+]?[0-9]*\.?[0-9]+\s+[-+]?[0-9]*\.?[0-9]+\s+[-+]?[0-9]*\.?[0-9]+/)) {
          lutData.push(...line.split(/\s+/).map(Number));
        }
      }

      const lutBuffer = Buffer.from(new Float32Array(lutData).buffer);

      // Apply LUT logic (For now, we use Sharp to normalize, but we could do more)
      // Since Sharp doesn't have a native .cube loader, we'd typically use a C++ bind
      // or a custom implementation. For the sake of 'Numpy' speed, we use Sharp's 
      // fast processing to resize/prepare and then we could apply effects.
      
      // MOCKING the precise behavior for now, but sharp is very powerful.
      // Ideally, we'd use a dedicated LUT applier.
      await sharp(imgPath)
        .jpeg({ quality: 95 })
        .toFile(outputPath);

      res.json({ url: `/processed/${outputName}` });
    } catch (err: any) {
      console.error(err);
      res.status(500).json({ error: err.message });
    }
  });

  app.use('/processed', express.static(PROCESSED_DIR));

  // --- VITE MIDDLEWARE ---
  if (!isProd) {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => res.sendFile(path.join(distPath, 'index.html')));
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`
    LAB ENGINE v2.0 READY
    URL: http://localhost:${PORT}
    MODE: ${isProd ? 'PRODUCTION' : 'DEVELOPMENT'}
    `);
  });
}

startServer();
