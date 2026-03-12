import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { marked } from 'marked';

const readme = readFileSync('README.md', 'utf-8');
const content = marked.parse(readme);

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vibestack — A project convention kit for AI-assisted development</title>
  <meta name="description" content="Drop a small set of opinionated files into any project to help both you and your AI agents work effectively as the codebase grows.">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
      line-height: 1.6;
      color: #c9d1d9;
      background: #0d1117;
    }
    .container {
      max-width: 860px;
      margin: 0 auto;
      padding: 3rem 2rem 4rem;
    }
    h1 { font-size: 2.5rem; margin-bottom: 0.5rem; color: #f0f6fc; }
    h2 { font-size: 1.5rem; margin-top: 2.5rem; margin-bottom: 1rem; color: #f0f6fc; padding-bottom: 0.3rem; border-bottom: 1px solid #21262d; }
    h3 { font-size: 1.25rem; margin-top: 2rem; margin-bottom: 0.75rem; color: #f0f6fc; }
    p { margin-bottom: 1rem; }
    a { color: #58a6ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
    strong { color: #f0f6fc; }
    code {
      font-family: 'SF Mono', 'Fira Code', 'Fira Mono', Menlo, Consolas, monospace;
      background: #161b22;
      padding: 0.2em 0.4em;
      border-radius: 6px;
      font-size: 0.875em;
    }
    pre {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 6px;
      padding: 1rem;
      overflow-x: auto;
      margin-bottom: 1rem;
    }
    pre code {
      background: none;
      padding: 0;
      font-size: 0.875rem;
      line-height: 1.5;
    }
    blockquote {
      border-left: 3px solid #3b82f6;
      padding: 0.5rem 1rem;
      margin-bottom: 1rem;
      color: #8b949e;
      background: #161b22;
      border-radius: 0 6px 6px 0;
    }
    hr {
      border: none;
      border-top: 1px solid #21262d;
      margin: 2rem 0;
    }
    ul, ol { padding-left: 2rem; margin-bottom: 1rem; }
    li { margin-bottom: 0.25rem; }
    img { max-width: 100%; }
    @media (max-width: 600px) {
      .container { padding: 1.5rem 1rem; }
      h1 { font-size: 2rem; }
    }
  </style>
</head>
<body>
  <div class="container">
    ${content}
  </div>
</body>
</html>`;

mkdirSync('public', { recursive: true });
writeFileSync('public/index.html', html);
console.log('Built public/index.html');
