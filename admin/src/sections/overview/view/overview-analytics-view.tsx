import type { Farmer, AnalyticsOverview } from 'src/services/api';

import dayjs from 'dayjs';
import { useState, useEffect, useCallback } from 'react';

import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import Card from '@mui/material/Card';
import Chip from '@mui/material/Chip';
import Table from '@mui/material/Table';
import Alert from '@mui/material/Alert';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import TableRow from '@mui/material/TableRow';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import Typography from '@mui/material/Typography';
import CardHeader from '@mui/material/CardHeader';
import TableContainer from '@mui/material/TableContainer';
import LinearProgress from '@mui/material/LinearProgress';

import { useRouter } from 'src/routes/hooks';

import { useAuth } from 'src/auth';
import { analyticsService } from 'src/services/api';
import { DashboardContent } from 'src/layouts/dashboard';

import { Iconify } from 'src/components/iconify';
import { Scrollbar } from 'src/components/scrollbar';

import { AnalyticsWidgetSummary } from '../analytics-widget-summary';
import { AnalyticsCurrentVisits } from '../analytics-current-visits';
import { FarmerDetailsDrawer } from '../../user/farmer-details-drawer';
import { AnalyticsConversionRates } from '../analytics-conversion-rates';

// ----------------------------------------------------------------------

export function OverviewAnalyticsView() {
  const { user } = useAuth();
  const router = useRouter();

  const [data, setData] = useState<AnalyticsOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Digital Twin drawer state
  const [selectedFarmer, setSelectedFarmer] = useState<Farmer | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const fetchOverview = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await analyticsService.getOverview();
      setData(res);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to load platform analytics.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchOverview();
  }, [fetchOverview]);

  const summary = data?.summary || {
    total_farmers: 0,
    active_farmers: 0,
    banned_farmers: 0,
    completed_profiles: 0,
    completion_rate: 0,
    total_land_acres: 0,
  };

  const topCrops = data?.top_crops || [];
  const topDistricts = data?.top_districts || [];
  const waterSources = data?.water_sources || [];
  const recentFarmers = data?.recent_farmers || [];

  return (
    <DashboardContent>
      <Box sx={{ mb: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            Welcome back, {user?.full_name?.split(' ')[0] || 'Admin'} 👋
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Krushi Setu Agricultural Platform & Farmer Operations Dashboard
          </Typography>
        </Box>
      {loading && <LinearProgress sx={{ mb: 3 }} />}

        <Button
          variant="outlined"
          color="primary"
          startIcon={<Iconify icon="solar:refresh-bold" />}
          onClick={fetchOverview}
          disabled={loading}
        >
          Refresh Data
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}


      <Grid container spacing={3}>
        {/* KPI 1: Total Farmers */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <AnalyticsWidgetSummary
            title="Total Farmers"
            percent={8.4}
            total={summary.total_farmers}
            color="primary"
            icon={<Iconify icon="solar:users-group-rounded-bold-duotone" width={38} />}
            chart={{
              categories: ['May', 'Jun', 'Jul', 'Aug', 'Sep'],
              series: [12, 28, 45, 65, summary.total_farmers || 80],
            }}
          />
        </Grid>

        {/* KPI 2: Active Farmers */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <AnalyticsWidgetSummary
            title="Active Farmers"
            percent={4.2}
            total={summary.active_farmers}
            color="info"
            icon={<Iconify icon="solar:user-check-bold-duotone" width={38} />}
            chart={{
              categories: ['May', 'Jun', 'Jul', 'Aug', 'Sep'],
              series: [10, 25, 40, 60, summary.active_farmers || 75],
            }}
          />
        </Grid>

        {/* KPI 3: Digital Twin Completion Rate */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <AnalyticsWidgetSummary
            title="Digital Twin Comp"
            percent={summary.completion_rate}
            total={summary.completed_profiles}
            color="warning"
            icon={<Iconify icon="solar:shield-check-bold-duotone" width={38} />}
            chart={{
              categories: ['May', 'Jun', 'Jul', 'Aug', 'Sep'],
              series: [5, 18, 30, 48, summary.completed_profiles || 55],
            }}
          />
        </Grid>

        {/* KPI 4: Total Land Under Management */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <AnalyticsWidgetSummary
            title="Total Land (Acres)"
            percent={12.5}
            total={summary.total_land_acres}
            color="error"
            icon={<Iconify icon="fluent:leaf-three-16-filled" width={38} />}
            chart={{
              categories: ['May', 'Jun', 'Jul', 'Aug', 'Sep'],
              series: [40, 90, 150, 220, summary.total_land_acres || 310],
            }}
          />
        </Grid>

        {/* Top Crops Cultivated */}
        <Grid size={{ xs: 12, md: 7 }}>
          <AnalyticsConversionRates
            title="Top Cultivated Crops"
            subheader="Distribution of major crops registered across farmer Digital Twins"
            chart={{
              categories: topCrops.map((c) => c.label),
              series: [
                {
                  name: 'Farmers Cultivating',
                  data: topCrops.map((c) => c.value),
                },
              ],
            }}
          />
        </Grid>

        {/* Regional District Distribution */}
        <Grid size={{ xs: 12, md: 5 }}>
          <AnalyticsCurrentVisits
            title="Farmer Regional Distribution"
            subheader="Geographic coverage across key farming districts"
            chart={{
              series: topDistricts.map((d) => ({
                label: d.label,
                value: d.value,
              })),
            }}
          />
        </Grid>

        {/* Water Resource Availability */}
        <Grid size={{ xs: 12, md: 4 }}>
          <AnalyticsCurrentVisits
            title="Irrigation & Water Sources"
            subheader="Primary water sources utilized on farm lands"
            chart={{
              series: waterSources.map((w) => ({
                label: w.label,
                value: w.value,
              })),
            }}
          />
        </Grid>

        {/* Recent Farmer Registrations */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card>
            <CardHeader
              title="Recent Farmer Registrations"
              subheader="Latest farmers onboarding to Krushi Setu"
              action={
                <Button
                  size="small"
                  color="primary"
                  onClick={() => router.push('/farmers')}
                  endIcon={<Iconify icon="eva:arrow-ios-forward-fill" />}
                >
                  View All Farmers
                </Button>
              }
            />

            <Scrollbar>
              <TableContainer sx={{ minWidth: 600 }}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Farmer</TableCell>
                      <TableCell>Location</TableCell>
                      <TableCell>Digital Twin</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell>Date</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {recentFarmers.length > 0 ? (
                      recentFarmers.map((f: any) => (
                        <TableRow
                          key={f.id}
                          hover
                          sx={{ cursor: 'pointer' }}
                          onClick={() => {
                            setSelectedFarmer(f);
                            setDrawerOpen(true);
                          }}
                        >
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                              <Avatar sx={{ bgcolor: 'primary.lighter', color: 'primary.dark', width: 36, height: 36, fontSize: '0.85rem', fontWeight: 600 }}>
                                {f.full_name?.charAt(0).toUpperCase() || 'F'}
                              </Avatar>
                              <Box>
                                <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                                  {f.full_name}
                                </Typography>
                                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                                  {f.phone_number || f.email}
                                </Typography>
                              </Box>
                            </Box>
                          </TableCell>

                          <TableCell>
                            <Typography variant="body2">
                              {f.district ? `${f.district}, ${f.state || ''}` : f.state || '—'}
                            </Typography>
                          </TableCell>

                          <TableCell>
                            {f.profile_completed ? (
                              <Chip label="Completed" size="small" color="success" variant="filled" />
                            ) : (
                              <Chip label="Pending" size="small" variant="outlined" color="warning" />
                            )}
                          </TableCell>

                          <TableCell>
                            <Chip
                              label={f.status}
                              size="small"
                              color={f.status === 'active' ? 'success' : 'error'}
                              variant="filled"
                            />
                          </TableCell>

                          <TableCell sx={{ color: 'text.secondary', fontSize: '0.8rem' }}>
                            {f.created_at ? dayjs(f.created_at).format('DD MMM') : '—'}
                          </TableCell>
                        </TableRow>
                      ))
                    ) : (
                      <TableRow>
                        <TableCell colSpan={5} align="center" sx={{ py: 3, color: 'text.secondary' }}>
                          No farmer registrations yet.
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            </Scrollbar>
          </Card>
        </Grid>
      </Grid>

      {/* Detail Drawer */}
      <FarmerDetailsDrawer
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        farmer={selectedFarmer}
      />
    </DashboardContent>
  );
}

