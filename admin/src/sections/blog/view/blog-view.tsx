import type { BlogPost } from 'src/services/api';

import { useState, useEffect, useCallback } from 'react';

import Box from '@mui/material/Box';
import Tab from '@mui/material/Tab';
import Card from '@mui/material/Card';
import Grid from '@mui/material/Grid';
import Tabs from '@mui/material/Tabs';
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import MenuItem from '@mui/material/MenuItem';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import Pagination from '@mui/material/Pagination';
import IconButton from '@mui/material/IconButton';
import CardContent from '@mui/material/CardContent';
import DialogTitle from '@mui/material/DialogTitle';
import OutlinedInput from '@mui/material/OutlinedInput';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import InputAdornment from '@mui/material/InputAdornment';
import CircularProgress from '@mui/material/CircularProgress';

import { blogService } from 'src/services/api';
import { DashboardContent } from 'src/layouts/dashboard';

import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

const CATEGORY_OPTIONS = [
  { value: 'scheme', label: 'Government Scheme', badgeColor: 'primary' },
  { value: 'pest', label: 'Pest & Disease Alert', badgeColor: 'error' },
  { value: 'weather', label: 'Weather Bulletin', badgeColor: 'warning' },
  { value: 'soil', label: 'Soil Health', badgeColor: 'success' },
  { value: 'farming_tips', label: 'Farming Tips', badgeColor: 'info' },
  { value: 'general', label: 'General Advice', badgeColor: 'default' },
];

export function BlogView() {
  const [blogs, setBlogs] = useState<BlogPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filters & Pagination
  const [currentTab, setCurrentTab] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  // Modals state
  const [openModal, setOpenModal] = useState(false);
  const [editingBlog, setEditingBlog] = useState<BlogPost | null>(null);
  const [viewingBlog, setViewingBlog] = useState<BlogPost | null>(null);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [uploadingImage, setUploadingImage] = useState(false);

  // Form State
  const [formValues, setFormValues] = useState({
    title: '',
    category: 'scheme',
    category_label: 'Government Scheme',
    summary: '',
    content: '',
    cover_image: '',
    tags: '',
    target_crops: '',
    status: 'published' as 'published' | 'draft',
  });

  const fetchBlogs = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await blogService.getBlogs({
        page,
        limit: 9,
        category: currentTab === 'all' ? undefined : currentTab,
        search: searchQuery.trim() ? searchQuery : undefined,
      });
      setBlogs(res.blogs);
      setTotalPages(res.total_pages);
    } catch (err: any) {
      console.error('Failed to fetch blogs:', err);
      setError(err?.response?.data?.detail || 'Failed to fetch blogs from server.');
    } finally {
      setLoading(false);
    }
  }, [page, currentTab, searchQuery]);

  useEffect(() => {
    fetchBlogs();
  }, [fetchBlogs]);

  const handleOpenCreateModal = () => {
    setEditingBlog(null);
    setFormValues({
      title: '',
      category: 'scheme',
      category_label: 'Government Scheme',
      summary: '',
      content: '',
      cover_image: '',
      tags: '',
      target_crops: '',
      status: 'published',
    });
    setOpenModal(true);
  };

  const handleOpenEditModal = (blog: BlogPost) => {
    setEditingBlog(blog);
    setFormValues({
      title: blog.title,
      category: blog.category || 'scheme',
      category_label: blog.category_label || 'Government Scheme',
      summary: blog.summary,
      content: blog.content,
      cover_image: blog.cover_image || '',
      tags: blog.tags ? blog.tags.join(', ') : '',
      target_crops: blog.target_crops ? blog.target_crops.join(', ') : '',
      status: blog.status || 'published',
    });
    setOpenModal(true);
  };

  const handleCategoryChange = (catValue: string) => {
    const opt = CATEGORY_OPTIONS.find((c) => c.value === catValue);
    setFormValues((prev) => ({
      ...prev,
      category: catValue,
      category_label: opt ? opt.label : catValue,
    }));
  };

  const handleImageFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadingImage(true);
    try {
      const res = await blogService.uploadImage(file);
      // If server returns relative path, prefix with backend host if needed
      const fullUrl = res.url.startsWith('/')
        ? `${import.meta.env.VITE_API_URL || 'http://localhost:8080'}${res.url}`
        : res.url;
      setFormValues((prev) => ({ ...prev, cover_image: fullUrl }));
    } catch (err) {
      console.error('Failed to upload image:', err);
      alert('Image upload failed. Please try again.');
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSubmitForm = async () => {
    if (!formValues.title.trim() || !formValues.summary.trim() || !formValues.content.trim()) {
      alert('Please fill in required fields: Title, Summary, and Content.');
      return;
    }

    const payload = {
      title: formValues.title,
      category: formValues.category,
      category_label: formValues.category_label,
      summary: formValues.summary,
      content: formValues.content,
      cover_image: formValues.cover_image,
      tags: formValues.tags ? formValues.tags.split(',').map((t) => t.trim()).filter(Boolean) : [],
      target_crops: formValues.target_crops
        ? formValues.target_crops.split(',').map((c) => c.trim()).filter(Boolean)
        : [],
      status: formValues.status,
    };

    try {
      if (editingBlog) {
        await blogService.updateBlog(editingBlog.id, payload);
      } else {
        await blogService.createBlog(payload);
      }
      setOpenModal(false);
      fetchBlogs();
    } catch (err: any) {
      console.error('Failed to save blog:', err);
      alert(err?.response?.data?.detail || 'Failed to save blog post.');
    }
  };

  const handleDeleteBlog = async (id: string) => {
    try {
      await blogService.deleteBlog(id);
      setDeleteConfirmId(null);
      fetchBlogs();
    } catch (err: any) {
      console.error('Failed to delete blog:', err);
      alert('Failed to delete blog post.');
    }
  };

  const getBadgeColor = (category: string) => {
    const opt = CATEGORY_OPTIONS.find((c) => c.value === category);
    return (opt?.badgeColor || 'default') as any;
  };

  return (
    <DashboardContent>
      {/* Top Header */}
      <Box
        sx={{
          mb: 4,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 2,
        }}
      >
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Blog & Advisory Management
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Create, manage, and publish agricultural blogs, government schemes, pest alerts, and crop advisories for farmers.
          </Typography>
        </Box>

        <Button
          variant="contained"
          color="primary"
          startIcon={<Iconify icon="mingcute:add-line" />}
          onClick={handleOpenCreateModal}
          sx={{ fontWeight: 600 }}
        >
          New Post
        </Button>
      </Box>

      {/* Filter & Search Bar */}
      <Card sx={{ p: 2, mb: 4 }}>
        <Box
          sx={{
            display: 'flex',
            flexDirection: { xs: 'column', md: 'row' },
            gap: 2,
            alignItems: { md: 'center' },
            justifyContent: 'space-between',
          }}
        >
          <Tabs
            value={currentTab}
            onChange={(_, val) => {
              setCurrentTab(val);
              setPage(1);
            }}
            variant="scrollable"
            scrollButtons="auto"
          >
            <Tab value="all" label="All Posts" />
            <Tab value="scheme" label="Government Schemes" />
            <Tab value="pest" label="Pest Alerts" />
            <Tab value="weather" label="Weather Alerts" />
            <Tab value="soil" label="Soil Health" />
            <Tab value="farming_tips" label="Farming Tips" />
          </Tabs>

          <OutlinedInput
            size="small"
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setPage(1);
            }}
            placeholder="Search blogs or advisories..."
            startAdornment={
              <InputAdornment position="start">
                <Iconify width={18} icon="eva:search-fill" sx={{ color: 'text.disabled' }} />
              </InputAdornment>
            }
            sx={{ minWidth: 260 }}
          />
        </Box>
      </Card>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Main Blog Cards Grid */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress color="primary" />
        </Box>
      ) : (
        <Grid container spacing={3}>
          {blogs.map((blog) => (
            <Grid key={blog.id} size={{ xs: 12, sm: 6, md: 4 }}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  borderRadius: 2,
                  transition: 'transform 0.2s, box-shadow 0.2s',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: (theme) => theme.shadows[4],
                  },
                }}
              >
                {/* Cover Image */}
                {blog.cover_image ? (
                  <Box
                    component="img"
                    src={blog.cover_image}
                    alt={blog.title}
                    sx={{ height: 180, width: '100%', objectFit: 'cover' }}
                  />
                ) : (
                  <Box
                    sx={{
                      height: 140,
                      bgcolor: 'background.neutral',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Iconify icon="solar:document-text-bold-duotone" width={48} sx={{ color: 'text.disabled' }} />
                  </Box>
                )}

                <CardContent sx={{ flex: 1, p: 3, display: 'flex', flexDirection: 'column' }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1.5 }}>
                    <Chip
                      label={blog.category_label || blog.category}
                      color={getBadgeColor(blog.category)}
                      size="small"
                      sx={{ fontWeight: 600, fontSize: '0.75rem' }}
                    />
                    <Chip
                      label={blog.status === 'published' ? 'Published' : 'Draft'}
                      variant="outlined"
                      color={blog.status === 'published' ? 'success' : 'default'}
                      size="small"
                      sx={{ fontSize: '0.7rem' }}
                    />
                  </Box>

                  <Typography variant="h6" sx={{ fontWeight: 700, mb: 1, minHeight: 48, lineHeight: 1.3 }}>
                    {blog.title}
                  </Typography>

                  <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2, flex: 1, lineHeight: 1.5 }}>
                    {blog.summary.length > 120 ? `${blog.summary.slice(0, 120)}...` : blog.summary}
                  </Typography>

                  {blog.target_crops && blog.target_crops.length > 0 && (
                    <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 2 }}>
                      {blog.target_crops.map((c) => (
                        <Chip key={c} label={c} size="small" variant="outlined" sx={{ fontSize: '0.7rem' }} />
                      ))}
                    </Box>
                  )}

                  {/* Actions Bar */}
                  <Box
                    sx={{
                      pt: 1.5,
                      borderTop: (theme) => `1px dashed ${theme.palette.divider}`,
                      display: 'flex',
                      justify: 'space-between',
                      alignItems: 'center',
                    }}
                  >
                    <Button
                      size="small"
                      color="inherit"
                      onClick={() => setViewingBlog(blog)}
                      startIcon={<Iconify icon="eva:eye-fill" />}
                    >
                      View
                    </Button>

                    <Box>
                      <IconButton size="small" color="primary" onClick={() => handleOpenEditModal(blog)}>
                        <Iconify icon="eva:edit-fill" />
                      </IconButton>
                      <IconButton size="small" color="error" onClick={() => setDeleteConfirmId(blog.id)}>
                        <Iconify icon="eva:trash-2-fill" />
                      </IconButton>
                    </Box>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}

          {blogs.length === 0 && (
            <Grid size={{ xs: 12 }}>
              <Box sx={{ p: 5, textAlign: 'center', bgcolor: 'background.neutral', borderRadius: 2 }}>
                <Typography variant="subtitle1" sx={{ color: 'text.secondary' }}>
                  No posts found matching search or category.
                </Typography>
              </Box>
            </Grid>
          )}
        </Grid>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <Pagination
          count={totalPages}
          page={page}
          onChange={(_, p) => setPage(p)}
          color="primary"
          sx={{ mt: 5, mx: 'auto', display: 'flex', justifyContent: 'center' }}
        />
      )}

      {/* Create / Edit Dialog */}
      <Dialog open={openModal} onClose={() => setOpenModal(false)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>
          {editingBlog ? 'Edit Blog Post / Advisory' : 'Create New Blog Post'}
        </DialogTitle>
        <DialogContent dividers sx={{ pt: 2 }}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
            <TextField
              label="Post Title"
              fullWidth
              value={formValues.title}
              onChange={(e) => setFormValues((prev) => ({ ...prev, title: e.target.value }))}
            />

            <Grid container spacing={2}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  select
                  label="Category"
                  fullWidth
                  value={formValues.category}
                  onChange={(e) => handleCategoryChange(e.target.value)}
                >
                  {CATEGORY_OPTIONS.map((opt) => (
                    <MenuItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>

              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  select
                  label="Status"
                  fullWidth
                  value={formValues.status}
                  onChange={(e) =>
                    setFormValues((prev) => ({ ...prev, status: e.target.value as 'published' | 'draft' }))
                  }
                >
                  <MenuItem value="published">Published</MenuItem>
                  <MenuItem value="draft">Draft</MenuItem>
                </TextField>
              </Grid>
            </Grid>

            <TextField
              label="Short Summary"
              fullWidth
              multiline
              rows={2}
              value={formValues.summary}
              onChange={(e) => setFormValues((prev) => ({ ...prev, summary: e.target.value }))}
            />

            <TextField
              label="Full Post Content (Markdown / Text)"
              fullWidth
              multiline
              rows={6}
              value={formValues.content}
              onChange={(e) => setFormValues((prev) => ({ ...prev, content: e.target.value }))}
            />

            {/* Cover Image Upload / URL */}
            <Box sx={{ p: 2, border: (theme) => `1px dashed ${theme.palette.divider}`, borderRadius: 1 }}>
              <Typography variant="subtitle2" sx={{ mb: 1 }}>
                Cover Image
              </Typography>
              <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                <Button variant="outlined" component="label" disabled={uploadingImage}>
                  {uploadingImage ? 'Uploading...' : 'Upload Image File'}
                  <input type="file" accept="image/*" hidden onChange={handleImageFileUpload} />
                </Button>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  or enter URL:
                </Typography>
                <TextField
                  size="small"
                  fullWidth
                  placeholder="https://example.com/image.jpg"
                  value={formValues.cover_image}
                  onChange={(e) => setFormValues((prev) => ({ ...prev, cover_image: e.target.value }))}
                />
              </Box>
              {formValues.cover_image && (
                <Box
                  component="img"
                  src={formValues.cover_image}
                  alt="Preview"
                  sx={{ mt: 2, height: 120, borderRadius: 1, objectFit: 'cover' }}
                />
              )}
            </Box>

            <Grid container spacing={2}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  label="Target Crops (comma separated)"
                  fullWidth
                  placeholder="Paddy, Wheat, Cotton"
                  value={formValues.target_crops}
                  onChange={(e) => setFormValues((prev) => ({ ...prev, target_crops: e.target.value }))}
                />
              </Grid>
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  label="Tags (comma separated)"
                  fullWidth
                  placeholder="Scheme, Insurance, Disease"
                  value={formValues.tags}
                  onChange={(e) => setFormValues((prev) => ({ ...prev, tags: e.target.value }))}
                />
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenModal(false)} color="inherit">
            Cancel
          </Button>
          <Button onClick={handleSubmitForm} variant="contained" color="primary">
            {editingBlog ? 'Save Changes' : 'Publish Post'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* View Detail Modal */}
      <Dialog open={!!viewingBlog} onClose={() => setViewingBlog(null)} maxWidth="sm" fullWidth>
        {viewingBlog && (
          <>
            <DialogTitle sx={{ fontWeight: 700 }}>{viewingBlog.title}</DialogTitle>
            <DialogContent dividers>
              {viewingBlog.cover_image && (
                <Box
                  component="img"
                  src={viewingBlog.cover_image}
                  alt={viewingBlog.title}
                  sx={{ width: '100%', height: 200, objectFit: 'cover', borderRadius: 1.5, mb: 2 }}
                />
              )}
              <Chip
                label={viewingBlog.category_label || viewingBlog.category}
                color={getBadgeColor(viewingBlog.category)}
                size="small"
                sx={{ mb: 2 }}
              />
              <Typography variant="subtitle2" sx={{ color: 'text.secondary', mb: 1 }}>
                Summary:
              </Typography>
              <Typography variant="body1" sx={{ mb: 2 }}>
                {viewingBlog.summary}
              </Typography>
              <Typography variant="subtitle2" sx={{ color: 'text.secondary', mb: 1 }}>
                Full Content:
              </Typography>
              <Typography
                variant="body2"
                sx={{ p: 2, bgcolor: 'background.neutral', borderRadius: 1, whiteSpace: 'pre-wrap' }}
              >
                {viewingBlog.content}
              </Typography>
            </DialogContent>
            <DialogActions sx={{ p: 2 }}>
              <Button onClick={() => setViewingBlog(null)} color="primary" variant="contained">
                Close
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Delete Confirmation Modal */}
      <Dialog open={!!deleteConfirmId} onClose={() => setDeleteConfirmId(null)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>Delete Post?</DialogTitle>
        <DialogContent>
          <Typography variant="body2">
            Are you sure you want to delete this blog post? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setDeleteConfirmId(null)} color="inherit">
            Cancel
          </Button>
          <Button
            onClick={() => deleteConfirmId && handleDeleteBlog(deleteConfirmId)}
            color="error"
            variant="contained"
          >
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </DashboardContent>
  );
}
