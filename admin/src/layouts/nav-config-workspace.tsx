import type { WorkspacesPopoverProps } from './components/workspaces-popover';

// ----------------------------------------------------------------------

export const _workspaces: WorkspacesPopoverProps['data'] = [
  {
    id: 'krushi-prod',
    name: 'Krushi Setu',
    plan: 'Production',
    logo: '/assets/icons/workspaces/logo-1.webp',
  },
  {
    id: 'krushi-stage',
    name: 'Krushi Setu',
    plan: 'Staging',
    logo: '/assets/icons/workspaces/logo-3.webp',
  },
  {
    id: 'krushi-dev',
    name: 'Krushi Setu',
    plan: 'Local',
    logo: '/assets/icons/workspaces/logo-2.webp',
  },
];
