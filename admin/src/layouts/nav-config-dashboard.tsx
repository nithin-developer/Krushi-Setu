import { Iconify } from 'src/components/iconify';
import { SvgColor } from 'src/components/svg-color';

// ----------------------------------------------------------------------

const icon = (name: string) => <SvgColor src={`/assets/icons/navbar/${name}.svg`} />;

export type NavItem = {
  title: string;
  path: string;
  icon: React.ReactNode;
  info?: React.ReactNode;
};

export const navData = [
  {
    title: 'Dashboard',
    path: '/',
    icon: icon('ic-analytics'),
  },
  {
    title: 'Farmers',
    path: '/farmers',
    icon: icon('ic-user'),
  },
  {
    title: 'Blog & Advisories',
    path: '/blog',
    icon: <Iconify width={22} icon="solar:pen-bold-duotone" sx={{ color: 'inherit' }} />,
  },
  {
    title: 'Advisory & Schemes',
    path: '/advisories',
    icon: <Iconify width={22} icon="fluent:leaf-three-16-filled" sx={{ color: 'inherit' }} />,
  },
  {
    title: 'Knowledge Base (RAG)',
    path: '/knowledge',
    icon: <Iconify width={22} icon="solar:document-text-bold-duotone" sx={{ color: 'inherit' }} />,
  },
  {
    title: 'Admin Management',
    path: '/admins',
    icon: <Iconify width={22} icon="solar:shield-user-bold-duotone" sx={{ color: 'inherit' }} />,
  },
];

