import { browser, dev } from '$app/environment';

export const APP_NAME = 'MG-Firma Legal';
export const WEBUI_HOSTNAME = browser ? (dev ? `` : ``) : '';
export const WEBUI_BASE_URL = browser ? (dev ? `` : ``) : '';
export const WEBUI_API_BASE_URL = `${WEBUI_BASE_URL}/api/v1`;
export const OLLAMA_API_BASE_URL = `${WEBUI_BASE_URL}/ollama`;
export const OPENAI_API_BASE_URL = `${WEBUI_BASE_URL}/openai`;
export const AUDIO_API_BASE_URL = `${WEBUI_BASE_URL}/api/v1/audio`;
export const IMAGES_API_BASE_URL = `${WEBUI_BASE_URL}/api/v1/images`;
export const RETRIEVAL_API_BASE_URL = `${WEBUI_BASE_URL}/api/v1/retrieval`;

export const WEBUI_VERSION = APP_VERSION;
export const WEBUI_BUILD_HASH = APP_BUILD_HASH;
export const REQUIRED_OLLAMA_VERSION = '0.1.16';

// PERFORMANCE FIX: Disable model profile images to prevent performance issues
// This prevents thousands of HTTP requests that slow down the application
export const DISABLE_MODEL_PROFILE_IMAGES = true;

export const SUPPORTED_FILE_TYPE = [
  'application/epub+zip',
  'application/pdf',
  'text/plain',
  'text/csv',
  'text/xml',
  'text/html',
  'text/x-python',
  'text/css',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/octet-stream',
  'application/x-javascript',
  'text/markdown',
  'audio/mpeg',
  'audio/wav',
  'audio/ogg',
  'audio/x-m4a'
];

export const SUPPORTED_FILE_EXTENSIONS = [
  'md',
  'rst',
  'go',
  'py',
  'java',
  'sh',
  'bat',
  'ps1',
  'cmd',
  'js',
  'ts',
  'css',
  'cpp',
  'hpp',
  'h',
  'c',
  'cs',
  'htm',
  'html',
  'sql',
  'log',
  'ini',
  'pl',
  'pm',
  'r',
  'dart',
  'dockerfile',
  'env',
  'php',
  'hs',
  'hsc',
  'lua',
  'nginxconf',
  'conf',
  'm',
  'mm',
  'plsql',
  'perl',
  'rb',
  'rs',
  'db2',
  'scala',
  'bash',
  'swift',
  'vue',
  'svelte',
  'doc',
  'docx',
  'pdf',
  'csv',
  'txt',
  'xls',
  'xlsx',
  'pptx',
  'ppt',
  'msg'
];

export const DEFAULT_CAPABILITIES = {
  file_context: true,
  vision: true,
  file_upload: true,
  web_search: true,
  image_generation: true,
  code_interpreter: true,
  terminal: true,
  citations: true,
  status_updates: true,
  usage: undefined,
  builtin_tools: true
};

export const PASTED_TEXT_CHARACTER_LIMIT = 1000;
