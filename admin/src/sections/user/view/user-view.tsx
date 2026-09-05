import type { Farmer } from 'src/services/api';
import type { SelectChangeEvent } from '@mui/material/Select';

import { useState, useEffect, useCallback } from 'react';

import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Table from '@mui/material/Table';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import Snackbar from '@mui/material/Snackbar';
import TableBody from '@mui/material/TableBody';
import Typography from '@mui/material/Typography';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TableContainer from '@mui/material/TableContainer';
import LinearProgress from '@mui/material/LinearProgress';
import TablePagination from '@mui/material/TablePagination';
import DialogContentText from '@mui/material/DialogContentText';

import { farmerService } from 'src/services/api';
import { DashboardContent } from 'src/layouts/dashboard';

import { Iconify } from 'src/components/iconify';
import { Scrollbar } from 'src/components/scrollbar';

import { emptyRows } from '../utils';
import { TableNoData } from '../table-no-data';
import { UserTableRow } from '../user-table-row';
import { UserTableHead } from '../user-table-head';
import { TableEmptyRows } from '../table-empty-rows';
import { UserTableToolbar } from '../user-table-toolbar';
import { FarmerDetailsDrawer } from '../farmer-details-drawer';

// ----------------------------------------------------------------------

export function UserView() {
  const [farmers, setFarmers] = useState<Farmer[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [filterName, setFilterName] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selected, setSelected] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  // Digital Twin Drawer state
  const [selectedFarmer, setSelectedFarmer] = useState<Farmer | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  // Delete Dialog state
  const [farmerToDelete, setFarmerToDelete] = useState<Farmer | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  // Notification state
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  const fetchFarmers = useCallback(async () => {
    setLoading(true);
    try {
      const res = await farmerService.getFarmers({
        page: page + 1,
        limit: rowsPerPage,
        search: filterName.trim() || undefined,
        status_filter: statusFilter !== 'all' ? statusFilter : undefined,
      });

      setFarmers(res.users || []);
      setTotal(res.total || 0);
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err.response?.data?.detail || 'Failed to fetch farmers list.',
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  }, [page, rowsPerPage, filterName, statusFilter]);

  useEffect(() => {
    fetchFarmers();
  }, [fetchFarmers]);

  const handleSelectAllRows = useCallback(
    (checked: boolean) => {
      if (checked) {
        setSelected(farmers.map((f) => f.id || f._id || ''));
        return;
      }
      setSelected([]);
    },
    [farmers]
  );

  const handleSelectRow = useCallback(
    (inputValue: string) => {
      const newSelected = selected.includes(inputValue)
        ? selected.filter((value) => value !== inputValue)
        : [...selected, inputValue];

      setSelected(newSelected);
    },
    [selected]
  );

  const handleViewDetails = (farmer: Farmer) => {
    setSelectedFarmer(farmer);
    setDrawerOpen(true);
  };

  const handleToggleStatus = async (farmer: Farmer) => {
    const newStatus = farmer.status === 'active' ? 'banned' : 'active';
    try {
      await farmerService.updateStatus(farmer.id || farmer._id || '', newStatus);
      setSnackbar({
        open: true,
        message: `Farmer status updated to ${newStatus}.`,
        severity: 'success',
      });
      fetchFarmers();
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err.response?.data?.detail || 'Failed to update farmer status.',
        severity: 'error',
      });
    }
  };

  const handleDeleteClick = (farmer: Farmer) => {
    setFarmerToDelete(farmer);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!farmerToDelete) return;
    try {
      await farmerService.deleteFarmer(farmerToDelete.id || farmerToDelete._id || '');
      setSnackbar({
        open: true,
        message: 'Farmer account deleted successfully.',
        severity: 'success',
      });
      setDeleteDialogOpen(false);
      setFarmerToDelete(null);
      fetchFarmers();
    } catch (err: any) {
      setSnackbar({
        open: true,
        message: err.response?.data?.detail || 'Failed to delete farmer account.',
        severity: 'error',
      });
    }
  };

  return (
    <DashboardContent>
      <Box
        sx={{
          mb: 3,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Registered Farmers
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Manage farmer accounts, view Digital Twin crop & soil profiles, and track jurisdiction
          </Typography>
        </Box>

        <Button
          variant="outlined"
          color="primary"
          startIcon={<Iconify icon="solar:refresh-bold" />}
          onClick={fetchFarmers}
          disabled={loading}
        >
          Refresh
        </Button>
      </Box>

      <Card >
        <UserTableToolbar
          numSelected={selected.length}
          filterName={filterName}
          statusFilter={statusFilter}
          onFilterName={(event: React.ChangeEvent<HTMLInputElement>) => {
            setFilterName(event.target.value);
            setPage(0);
          }}
          onStatusFilterChange={(event: SelectChangeEvent<string>) => {
            setStatusFilter(event.target.value);
            setPage(0);
          }}
        />

        {loading && <LinearProgress />}

        <Scrollbar>
          <TableContainer sx={{ overflow: 'unset' }}>
            <Table sx={{ minWidth: 800 }}>
              <UserTableHead
                order="asc"
                orderBy="name"
                rowCount={farmers.length}
                numSelected={selected.length}
                onSort={() => {}}
                onSelectAllRows={handleSelectAllRows}
                headLabel={[
                  { id: 'name', label: 'Farmer & Contact' },
                  { id: 'location', label: 'Location' },
                  { id: 'crops', label: 'Crops Cultivated' },
                  { id: 'digital_twin', label: 'Digital Twin', align: 'center' },
                  { id: 'status', label: 'Status' },
                  { id: 'created_at', label: 'Registered' },
                  { id: '' },
                ]}
              />
              <TableBody>
                {farmers.map((row) => {
                  const rowId = row.id || row._id || '';
                  return (
                    <UserTableRow
                      key={rowId}
                      row={row}
                      selected={selected.includes(rowId)}
                      onSelectRow={() => handleSelectRow(rowId)}
                      onViewDetails={handleViewDetails}
                      onToggleStatus={handleToggleStatus}
                      onDelete={handleDeleteClick}
                    />
                  );
                })}

                <TableEmptyRows
                  height={68}
                  emptyRows={emptyRows(page, rowsPerPage, farmers.length)}
                />

                {!loading && farmers.length === 0 && (
                  <TableNoData searchQuery={filterName || statusFilter} />
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Scrollbar>

        <TablePagination
          component="div"
          page={page}
          count={total}
          rowsPerPage={rowsPerPage}
          onPageChange={(e, newPage) => setPage(newPage)}
          rowsPerPageOptions={[5, 10, 25, 50]}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
        />
      </Card>


      {/* Slide-over Farmer Digital Twin Drawer */}
      <FarmerDetailsDrawer
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        farmer={selectedFarmer}
      />

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
      >
        <DialogTitle sx={{ fontWeight: 600 }}>Delete Farmer Account?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete the account for <strong>{farmerToDelete?.full_name}</strong>? This will permanently remove their Digital Twin profile and application records.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setDeleteDialogOpen(false)} color="inherit">
            Cancel
          </Button>
          <Button onClick={handleConfirmDelete} color="error" variant="contained">
            Delete Farmer
          </Button>
        </DialogActions>
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

