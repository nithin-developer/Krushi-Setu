import { useState, useEffect, useCallback } from 'react';

import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Table from '@mui/material/Table';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import Tooltip from '@mui/material/Tooltip';
import TableRow from '@mui/material/TableRow';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import Typography from '@mui/material/Typography';
import TableContainer from '@mui/material/TableContainer';
import TablePagination from '@mui/material/TablePagination';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import IconButton from '@mui/material/IconButton';
import LinearProgress from '@mui/material/LinearProgress';
import Alert from '@mui/material/Alert';
import Paper from '@mui/material/Paper';

import { DashboardContent } from 'src/layouts/dashboard';
import { Iconify } from 'src/components/iconify';
import { Scrollbar } from 'src/components/scrollbar';
import {
  knowledgeService,
  CollectionInfo,
  DocumentSummary,
  DocumentDetail,
  SearchResultItem,
} from 'src/services/api';

// ----------------------------------------------------------------------

const CATEGORIES = [
  { value: 'all', label: 'All Categories' },
  { value: 'government_scheme', label: 'Government Scheme' },
  { value: 'pest_disease', label: 'Pest & Disease' },
  { value: 'crop_guide', label: 'Crop Cultivation Guide' },
  { value: 'soil_health', label: 'Soil & Fertilizer' },
  { value: 'weather', label: 'Weather & Irrigation' },
  { value: 'general', label: 'General Agriculture' },
];

export function KnowledgeView() {
  const [activeTab, setActiveTab] = useState<'documents' | 'ingest' | 'search'>('documents');
  const [collectionInfo, setCollectionInfo] = useState<CollectionInfo | null>(null);
  const [documents, setDocuments] = useState<DocumentSummary[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');

  // Pagination
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // Ingest form state
  const [ingestMode, setIngestMode] = useState<'file' | 'text'>('file');
  const [ingestTitle, setIngestTitle] = useState<string>('');
  const [ingestContent, setIngestContent] = useState<string>('');
  const [ingestCategory, setIngestCategory] = useState<string>('general');
  const [ingestLanguage, setIngestLanguage] = useState<string>('en');
  const [ingestRegion, setIngestRegion] = useState<string>('all_india');
  const [ingestTags, setIngestTags] = useState<string>('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [ingestLoading, setIngestLoading] = useState<boolean>(false);
  const [ingestMsg, setIngestMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Document Detail Dialog state
  const [selectedDoc, setSelectedDoc] = useState<DocumentDetail | null>(null);

  // Sandbox Search state
  const [sandboxQuery, setSandboxQuery] = useState<string>('');
  const [sandboxCategory, setSandboxCategory] = useState<string>('all');
  const [sandboxResults, setSandboxResults] = useState<SearchResultItem[]>([]);
  const [sandboxLoading, setSandboxLoading] = useState<boolean>(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [infoRes, docsRes] = await Promise.all([
        knowledgeService.getInfo(),
        knowledgeService.getDocuments(),
      ]);
      setCollectionInfo(infoRes);
      setDocuments(docsRes.documents || []);
    } catch (err) {
      console.error('Failed to load knowledge data:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleDeleteDocument = async (documentId: string) => {
    if (!window.confirm('Are you sure you want to delete this document and all its vector chunks?')) {
      return;
    }
    try {
      await knowledgeService.deleteDocument(documentId);
      fetchData();
    } catch (err) {
      alert('Failed to delete document');
    }
  };

  const handleViewDetail = async (documentId: string) => {
    try {
      const detail = await knowledgeService.getDocumentById(documentId);
      setSelectedDoc(detail);
    } catch (err) {
      alert('Failed to fetch document detail');
    }
  };

  const handleIngestSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIngestLoading(true);
    setIngestMsg(null);

    try {
      if (ingestMode === 'file') {
        if (!selectedFile) {
          setIngestMsg({ type: 'error', text: 'Please select a file (.md, .pdf, .txt)' });
          setIngestLoading(false);
          return;
        }
        const formData = new FormData();
        formData.append('file', selectedFile);
        formData.append('category', ingestCategory);
        formData.append('language', ingestLanguage);
        formData.append('region', ingestRegion);
        formData.append('tags', ingestTags);

        await knowledgeService.ingestFile(formData);
        setIngestMsg({ type: 'success', text: `Successfully ingested file: ${selectedFile.name}` });
        setSelectedFile(null);
      } else {
        if (!ingestTitle.trim() || !ingestContent.trim()) {
          setIngestMsg({ type: 'error', text: 'Title and content are required.' });
          setIngestLoading(false);
          return;
        }
        await knowledgeService.ingestText({
          title: ingestTitle,
          content: ingestContent,
          category: ingestCategory,
          language: ingestLanguage,
          region: ingestRegion,
          tags: ingestTags ? ingestTags.split(',').map((t) => t.trim()) : [],
        });
        setIngestMsg({ type: 'success', text: `Successfully ingested text article: ${ingestTitle}` });
        setIngestTitle('');
        setIngestContent('');
      }
      fetchData();
    } catch (err: any) {
      setIngestMsg({ type: 'error', text: err.response?.data?.detail || 'Ingestion failed' });
    } finally {
      setIngestLoading(false);
    }
  };

  const handleSandboxSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sandboxQuery.trim()) return;
    setSandboxLoading(true);
    try {
      const res = await knowledgeService.search({
        query: sandboxQuery,
        category: sandboxCategory === 'all' ? undefined : sandboxCategory,
        top_k: 5,
      });
      setSandboxResults(res.results || []);
    } catch (err) {
      console.error('Sandbox search failed:', err);
    } finally {
      setSandboxLoading(false);
    }
  };

  const filteredDocuments = documents.filter((doc) => {
    const matchesSearch =
      doc.document_title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.source_file.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || doc.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  return (
    <DashboardContent maxWidth="xl">
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, mb: 1 }}>
            Knowledge Base Management (RAG)
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            Manage agricultural knowledge documents, Qdrant vector embeddings, and retrieval quality.
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Iconify icon="mingcute:add-line" />}
          onClick={() => setActiveTab('ingest')}
        >
          Ingest Knowledge
        </Button>
      </Box>

      {/* Top Overview Stat Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Card sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 1.5,
                bgcolor: 'primary.lighter',
                color: 'primary.main',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Iconify icon="solar:document-bold" width={28} />
            </Box>
            <Box>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                {documents.length}
              </Typography>
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                Indexed Documents
              </Typography>
            </Box>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Card sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 1.5,
                bgcolor: 'success.lighter',
                color: 'success.main',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Iconify icon="solar:layers-bold" width={28} />
            </Box>
            <Box>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                {collectionInfo?.points_count ?? documents.reduce((sum, d) => sum + d.chunks_count, 0)}
              </Typography>
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                Vector Chunks (1024d)
              </Typography>
            </Box>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Card sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 1.5,
                bgcolor: 'info.lighter',
                color: 'info.main',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Iconify icon="solar:database-bold" width={28} />
            </Box>
            <Box>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                Qdrant DB
              </Typography>
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                Status: {collectionInfo?.status || 'Active'}
              </Typography>
            </Box>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Card sx={{ p: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: 1.5,
                bgcolor: 'warning.lighter',
                color: 'warning.main',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Iconify icon="solar:cpu-bold" width={28} />
            </Box>
            <Box>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                BGE-M3
              </Typography>
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                Embeddings Model
              </Typography>
            </Box>
          </Card>
        </Grid>
      </Grid>

      {/* Main Tabs Navigation */}
      <Card>
        <Tabs
          value={activeTab}
          onChange={(_, val) => setActiveTab(val)}
          sx={{ px: 3, pt: 2, borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="Document Library" value="documents" />
          <Tab label="Ingest New Knowledge" value="ingest" />
          <Tab label="Search Sandbox (Tester)" value="search" />
        </Tabs>

        {loading && <LinearProgress />}

        {/* Tab 1: Document Library */}
        {activeTab === 'documents' && (
          <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
              <TextField
                size="small"
                placeholder="Search documents by title or file..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                sx={{ width: 320 }}
                InputProps={{
                  startAdornment: <Iconify icon="eva:search-fill" sx={{ color: 'text.disabled', mr: 1 }} />,
                }}
              />
              <TextField
                select
                size="small"
                label="Category"
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                sx={{ width: 220 }}
              >
                {CATEGORIES.map((c) => (
                  <MenuItem key={c.value} value={c.value}>
                    {c.label}
                  </MenuItem>
                ))}
              </TextField>
            </Box>

            <TableContainer component={Paper} variant="outlined">
              <Scrollbar>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Document Title</TableCell>
                      <TableCell>Source File</TableCell>
                      <TableCell>Category</TableCell>
                      <TableCell align="center">Chunks</TableCell>
                      <TableCell>Language</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filteredDocuments
                      .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                      .map((doc) => (
                        <TableRow key={doc.document_id} hover>
                          <TableCell sx={{ fontWeight: 600 }}>{doc.document_title}</TableCell>
                          <TableCell sx={{ color: 'text.secondary', fontFamily: 'monospace' }}>
                            {doc.source_file || 'Text Ingest'}
                          </TableCell>
                          <TableCell>
                            <Chip
                              label={doc.category}
                              size="small"
                              color={
                                doc.category === 'government_scheme'
                                  ? 'primary'
                                  : doc.category === 'pest_disease'
                                  ? 'error'
                                  : 'info'
                              }
                              variant="outlined"
                            />
                          </TableCell>
                          <TableCell align="center">
                            <Chip label={`${doc.chunks_count} chunks`} size="small" variant="outlined" />
                          </TableCell>
                          <TableCell sx={{ textTransform: 'uppercase' }}>{doc.language}</TableCell>
                          <TableCell align="right">
                            <Tooltip title="View Chunks">
                              <IconButton onClick={() => handleViewDetail(doc.document_id)} color="primary">
                                <Iconify icon="solar:eye-bold" />
                              </IconButton>
                            </Tooltip>
                            <Tooltip title="Delete Document">
                              <IconButton onClick={() => handleDeleteDocument(doc.document_id)} color="error">
                                <Iconify icon="solar:trash-bin-trash-bold" />
                              </IconButton>
                            </Tooltip>
                          </TableCell>
                        </TableRow>
                      ))}

                    {filteredDocuments.length === 0 && !loading && (
                      <TableRow>
                        <TableCell colSpan={6} align="center" sx={{ py: 6 }}>
                          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                            No knowledge documents found.
                          </Typography>
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </Scrollbar>
            </TableContainer>

            <TablePagination
              component="div"
              count={filteredDocuments.length}
              page={page}
              onPageChange={(_, newPage) => setPage(newPage)}
              rowsPerPage={rowsPerPage}
              onRowsPerPageChange={(e) => {
                setRowsPerPage(parseInt(e.target.value, 10));
                setPage(0);
              }}
            />
          </Box>
        )}

        {/* Tab 2: Ingest New Knowledge */}
        {activeTab === 'ingest' && (
          <Box component="form" onSubmit={handleIngestSubmit} sx={{ p: 4, maxWidth: 800, mx: 'auto' }}>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Ingest New Agricultural Document / Article
            </Typography>

            {ingestMsg && (
              <Alert severity={ingestMsg.type} sx={{ mb: 3 }}>
                {ingestMsg.text}
              </Alert>
            )}

            <Box sx={{ mb: 3 }}>
              <Tabs value={ingestMode} onChange={(_, val) => setIngestMode(val)} sx={{ mb: 2 }}>
                <Tab label="Upload Document File (.md, .pdf, .txt)" value="file" />
                <Tab label="Enter Raw Text Article" value="text" />
              </Tabs>
            </Box>

            <Grid container spacing={2.5}>
              {ingestMode === 'file' ? (
                <Grid size={{ xs: 12 }}>
                  <Button
                    variant="outlined"
                    component="label"
                    fullWidth
                    sx={{ p: 4, borderStyle: 'dashed', flexDirection: 'column', gap: 1 }}
                  >
                    <Iconify icon="solar:upload-square-bold" width={40} color="primary.main" />
                    <Typography variant="subtitle2">
                      {selectedFile ? selectedFile.name : 'Click to select Markdown, PDF, or Text file'}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      Max 20MB. Document will be automatically chunked and embedded using BGE-M3.
                    </Typography>
                    <input
                      type="file"
                      hidden
                      accept=".md,.pdf,.txt"
                      onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
                    />
                  </Button>
                </Grid>
              ) : (
                <>
                  <Grid size={{ xs: 12 }}>
                    <TextField
                      fullWidth
                      label="Document Title"
                      value={ingestTitle}
                      onChange={(e) => setIngestTitle(e.target.value)}
                      placeholder="e.g. Tomato Leaf Curl Virus Prevention & Management"
                      required
                    />
                  </Grid>
                  <Grid size={{ xs: 12 }}>
                    <TextField
                      fullWidth
                      multiline
                      rows={6}
                      label="Article Content (Markdown or Plain Text)"
                      value={ingestContent}
                      onChange={(e) => setIngestContent(e.target.value)}
                      placeholder="Enter detailed content..."
                      required
                    />
                  </Grid>
                </>
              )}

              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  select
                  fullWidth
                  label="Category"
                  value={ingestCategory}
                  onChange={(e) => setIngestCategory(e.target.value)}
                >
                  {CATEGORIES.filter((c) => c.value !== 'all').map((c) => (
                    <MenuItem key={c.value} value={c.value}>
                      {c.label}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>

              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  select
                  fullWidth
                  label="Language"
                  value={ingestLanguage}
                  onChange={(e) => setIngestLanguage(e.target.value)}
                >
                  <MenuItem value="en">English</MenuItem>
                  <MenuItem value="kn">Kannada</MenuItem>
                  <MenuItem value="hi">Hindi</MenuItem>
                </TextField>
              </Grid>

              <Grid size={{ xs: 12 }}>
                <TextField
                  fullWidth
                  label="Tags (comma separated)"
                  value={ingestTags}
                  onChange={(e) => setIngestTags(e.target.value)}
                  placeholder="e.g. pm-kisan, subsidy, tomato, pest"
                />
              </Grid>

              <Grid size={{ xs: 12 }} sx={{ mt: 2 }}>
                <Button
                  type="submit"
                  variant="contained"
                  size="large"
                  fullWidth
                  disabled={ingestLoading}
                  startIcon={<Iconify icon="solar:file-check-bold" />}
                >
                  {ingestLoading ? 'Ingesting & Embedding...' : 'Ingest Document into Qdrant'}
                </Button>
              </Grid>
            </Grid>
          </Box>
        )}

        {/* Tab 3: Search Sandbox */}
        {activeTab === 'search' && (
          <Box sx={{ p: 4 }}>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Interactive Semantic Search Sandbox
            </Typography>
            <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3 }}>
              Test how query terms are retrieved from Qdrant and score-reranked in real time.
            </Typography>

            <Box component="form" onSubmit={handleSandboxSearch} sx={{ display: 'flex', gap: 2, mb: 4 }}>
              <TextField
                fullWidth
                placeholder="Enter query in Kannada or English (e.g. PM-KISAN, ರಾಗಿ ಬೆಳೆ, Tomato blight)..."
                value={sandboxQuery}
                onChange={(e) => setSandboxQuery(e.target.value)}
              />
              <TextField
                select
                value={sandboxCategory}
                onChange={(e) => setSandboxCategory(e.target.value)}
                sx={{ width: 220 }}
              >
                {CATEGORIES.map((c) => (
                  <MenuItem key={c.value} value={c.value}>
                    {c.label}
                  </MenuItem>
                ))}
              </TextField>
              <Button
                type="submit"
                variant="contained"
                disabled={sandboxLoading}
                startIcon={<Iconify icon="eva:search-fill" />}
                sx={{ px: 4 }}
              >
                Search
              </Button>
            </Box>

            {sandboxLoading && <LinearProgress sx={{ mb: 3 }} />}

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {sandboxResults.map((item, idx) => (
                <Card key={idx} variant="outlined" sx={{ p: 2.5 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                    <Typography variant="subtitle1" sx={{ fontWeight: 700, color: 'primary.main' }}>
                      {item.document_title} {item.section_heading ? `> ${item.section_heading}` : ''}
                    </Typography>
                    <Chip
                      label={`Relevance Score: ${(item.score * 100).toFixed(1)}%`}
                      color={item.score > 0.6 ? 'success' : 'warning'}
                      size="small"
                    />
                  </Box>
                  <Typography variant="body2" sx={{ whiteSpace: 'pre-line', bgcolor: 'grey.100', p: 2, borderRadius: 1 }}>
                    {item.content}
                  </Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary', mt: 1, display: 'block' }}>
                    Source: {item.source_file || 'Text Ingest'} | Category: {item.category}
                  </Typography>
                </Card>
              ))}

              {sandboxResults.length === 0 && !sandboxLoading && sandboxQuery && (
                <Alert severity="info">No matching vector chunks found for this query.</Alert>
              )}
            </Box>
          </Box>
        )}
      </Card>

      {/* Document Detail & Chunks Modal */}
      <Dialog open={Boolean(selectedDoc)} onClose={() => setSelectedDoc(null)} maxWidth="md" fullWidth>
        {selectedDoc && (
          <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>
                {selectedDoc.document_title}
              </Typography>
              <IconButton onClick={() => setSelectedDoc(null)}>
                <Iconify icon="mingcute:close-line" />
              </IconButton>
            </Box>

            <Typography variant="body2" sx={{ color: 'text.secondary', mb: 3 }}>
              Category: <b>{selectedDoc.category}</b> | Chunks: <b>{selectedDoc.chunks_count}</b> | File:{' '}
              <b>{selectedDoc.source_file}</b>
            </Typography>

            <Box sx={{ maxHeight: 500, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 2 }}>
              {selectedDoc.chunks.map((chunk) => (
                <Paper key={chunk.chunk_id} variant="outlined" sx={{ p: 2 }}>
                  <Typography variant="subtitle2" sx={{ color: 'primary.main', mb: 1 }}>
                    Chunk #{chunk.chunk_index + 1}{' '}
                    {chunk.section_heading ? `— ${chunk.section_heading}` : ''}
                  </Typography>
                  <Typography variant="body2" sx={{ whiteSpace: 'pre-line' }}>
                    {chunk.content}
                  </Typography>
                </Paper>
              ))}
            </Box>
          </Box>
        )}
      </Dialog>
    </DashboardContent>
  );
}
