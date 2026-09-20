import packageJson from '../package.json';

// ----------------------------------------------------------------------

export type ConfigValue = {
  appName: string;
  appVersion: string;
  serverUrl: string;
};

export const CONFIG: ConfigValue = {
  appName: 'Krushi Setu Admin',
  appVersion: packageJson.version,
  serverUrl: import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1',
};

