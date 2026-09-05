import type { AdminUser } from 'src/services/api';

import dayjs from 'dayjs';
import { useState, useEffect, useCallback } from 'react';

import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Chip from '@mui/material/Chip';
import Table from '@mui/material/Table';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Avatar from '@mui/material/Avatar';
import Dialog from '@mui/material/Dialog';
import TableRow from '@mui/material/TableRow';
import MenuItem from '@mui/material/MenuItem';
import Snackbar from '@mui/material/Snackbar';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TableContainer from '@mui/material/TableContainer';
import LinearProgress from '@mui/material/LinearProgress';

import { useAuth } from 'src/auth';
import { DashboardContent } from 'src/layouts/dashboard';
import { adminManagementService } from 'src/services/api';

import { Iconify } from 'src/components/iconify';
import { Scrollbar } from 'src/components/scrollbar';

// ----------------------------------------------------------------------

export function AdminManagementView() {
  const { user: currentAdmin } = useAuth();

  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);

  // Form state
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('admin');
  const [formLoading, setFormLoading] = useState(false);
  const [formError, setFormError] = useState('');

  // Notification state
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  const fetchAdmins = useCallback(async () => {
    setLoading(true);
    try {
      const res = await adminManagementService.getAdmins();
      setAdmins(res.admins || []);
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err.response?.data?.detail || 'Failed to fetch administrators.',
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAdmins();
  }, [fetchAdmins]);

  const handleCreateAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim() || !email.trim() || !password.trim()) {
      setFormError('Please fill in all required fields.');
      return;
    }

    setFormLoading(true);
    setFormError('');

    try {
      await adminManagementService.createAdmin({
        full_name: fullName.trim(),
        email: email.trim(),
        password,
        role,
      });

      setSnackbar({
        open: true,
        message: 'Administrator created successfully.',
        severity: 'success',
      });
      setCreateDialogOpen(false);
      setFullName('');
      setEmail('');
      setPassword('');
      setRole('admin');
      fetchAdmins();
    } catch (err: any) {
      setFormError(err.response?.data?.detail || 'Failed to create administrator.');
    } finally {
      setFormLoading(false);
    }
  };

  const handleToggleStatus = async (targetAdmin: AdminUser) => {
    const targetId = targetAdmin.id || targetAdmin._id || '';
    const newStatus = targetAdmin.status === 'active' ? 'inactive' : 'active';
    try {
      await adminManagementService.updateStatus(targetId, newStatus);
      setSnackbar({
        open: true,
        message: `Admin status updated to ${newStatus}.`,
        severity: 'success',
      });
      fetchAdmins();
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err.response?.data?.detail || 'Failed to update admin status.',
        severity: 'error',
      });
    }
  };

  const handleDeleteAdmin = async (targetAdmin: AdminUser) => {
    const targetId = targetAdmin.id || targetAdmin._id || '';
    if (window.confirm(`Are you sure you want to remove administrator ${targetAdmin.full_name}?`)) {
      try {
        await adminManagementService.deleteAdmin(targetId);
        setSnackbar({
          open: true,
          message: 'Administrator account deleted.',
          severity: 'success',
        });
        fetchAdmins();
      } catch (err: any) {
        setSnackbar({
          open: true,
          message: err.response?.data?.detail || 'Failed to delete administrator.',
          severity: 'error',
        });
      }
    }
  };

  return (
    <DashboardContent>
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Administrator Access & Roles
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Manage staff accounts, assign operations roles, and audit access credentials
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', gap: 1.5 }}>
          <Button
            variant="outlined"
            startIcon={<Iconify icon="solar:refresh-bold" />}
            onClick={fetchAdmins}
            disabled={loading}
          >
            Refresh
          </Button>

          <Button
            variant="contained"
            color="primary"
            startIcon={<Iconify icon="mingcute:add-line" />}
            onClick={() => setCreateDialogOpen(true)}
          >
            Add Administrator
          </Button>
        </Box>
      </Box>

      <Card>
        {loading && <LinearProgress />}

        <Scrollbar>
          <TableContainer sx={{ minWidth: 700 }}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Administrator</TableCell>
                  <TableCell>Role</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Last Login</TableCell>
                  <TableCell>Created</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>

              <TableBody>
                {admins.map((adm) => {
                  const admId = adm.id || adm._id || '';
                  const isCurrent = (currentAdmin?.id || currentAdmin?._id) === admId;

                  return (
                    <TableRow key={admId} hover>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                          <Avatar sx={{ bgcolor: 'primary.main', fontWeight: 600, width: 40, height: 40 }}>
                            {adm.full_name?.charAt(0).toUpperCase()}
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                              {adm.full_name} {isCurrent && '(You)'}
                            </Typography>
                            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                              {adm.email}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>

                      <TableCell>
                        <Chip
                          label={adm.role.replace('_', ' ').toUpperCase()}
                          size="small"
                          color={adm.role === 'super_admin' ? 'primary' : 'default'}
                          variant="outlined"
                          sx={{ fontWeight: 600, fontSize: '0.7rem' }}
                        />
                      </TableCell>

                      <TableCell>
                        <Chip
                          label={adm.status || 'active'}
                          size="small"
                          color={adm.status === 'active' || !adm.status ? 'success' : 'default'}
                          variant="filled"
                        />
                      </TableCell>

                      <TableCell sx={{ color: 'text.secondary', fontSize: '0.85rem' }}>
                        {adm.last_login ? dayjs(adm.last_login).format('DD MMM YYYY, hh:mm A') : 'Never'}
                      </TableCell>

                      <TableCell sx={{ color: 'text.secondary', fontSize: '0.85rem' }}>
                        {adm.created_at ? dayjs(adm.created_at).format('DD MMM YYYY') : '—'}
                      </TableCell>

                      <TableCell align="right">
                        {!isCurrent && (
                          <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1 }}>
                            <IconButton
                              size="small"
                              onClick={() => handleToggleStatus(adm)}
                              title={adm.status === 'active' ? 'Deactivate' : 'Activate'}
                            >
                              <Iconify
                                icon={adm.status === 'active' ? 'solar:user-block-bold' : 'solar:user-check-bold'}
                                sx={{ color: adm.status === 'active' ? 'warning.main' : 'success.main' }}
                              />
                            </IconButton>

                            <IconButton
                              size="small"
                              onClick={() => handleDeleteAdmin(adm)}
                              sx={{ color: 'error.main' }}
                              title="Delete Admin"
                            >
                              <Iconify icon="solar:trash-bin-trash-bold" />
                            </IconButton>
                          </Box>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}

                {!loading && admins.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={6} align="center" sx={{ py: 4, color: 'text.secondary' }}>
                      No administrators found.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Scrollbar>
      </Card>

      {/* Add Administrator Dialog */}
      <Dialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Create New Administrator</DialogTitle>
        <Box component="form" onSubmit={handleCreateAdmin}>
          <DialogContent dividers sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
            {formError && <Alert severity="error">{formError}</Alert>}

            <TextField
              label="Full Name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              required
              fullWidth
            />

            <TextField
              label="Email Address"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              fullWidth
            />

            <TextField
              label="Initial Password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              fullWidth
            />

            <TextField
              select
              label="Administrator Role"
              value={role}
              onChange={(e) => setRole(e.target.value)}
              fullWidth
            >
              <MenuItem value="super_admin">Super Administrator (Full Access)</MenuItem>
              <MenuItem value="admin">Platform Admin</MenuItem>
              <MenuItem value="moderator">Operations & Support Moderator</MenuItem>
            </TextField>
          </DialogContent>

          <DialogActions sx={{ p: 2 }}>
            <Button onClick={() => setCreateDialogOpen(false)} color="inherit" disabled={formLoading}>
              Cancel
            </Button>
            <Button type="submit" variant="contained" color="primary" disabled={formLoading}>
              {formLoading ? 'Creating...' : 'Create Admin'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>

      {/* Snackbar Feedback */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert severity={snackbar.severity} onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </DashboardContent>
  );
}
