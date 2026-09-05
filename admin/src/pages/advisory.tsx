import { CONFIG } from 'src/config-global';

import { AdvisoryView } from 'src/sections/advisory/view/advisory-view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Advisory & Schemes - ${CONFIG.appName}`}</title>
      <AdvisoryView />
    </>
  );
}
