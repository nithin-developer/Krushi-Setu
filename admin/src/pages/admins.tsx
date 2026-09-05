import { CONFIG } from 'src/config-global';

import { AdminManagementView } from 'src/sections/admin-management/view/admin-management-view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Admin Management - ${CONFIG.appName}`}</title>
      <AdminManagementView />
    </>
  );
}
