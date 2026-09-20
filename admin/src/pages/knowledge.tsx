import { CONFIG } from 'src/config-global';
import { KnowledgeView } from 'src/sections/knowledge/knowledge-view';

// ----------------------------------------------------------------------

export default function KnowledgePage() {
  return (
    <>
      <title>{`Knowledge Base (RAG) - ${CONFIG.appName}`}</title>
      <KnowledgeView />
    </>
  );
}
