import type { Farmer } from 'src/services/api';

import dayjs from 'dayjs';

import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Card from '@mui/material/Card';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Drawer from '@mui/material/Drawer';
import Avatar from '@mui/material/Avatar';
import Divider from '@mui/material/Divider';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';

import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

type Props = {
  open: boolean;
  onClose: () => void;
  farmer: Farmer | null;
};

export function FarmerDetailsDrawer({ open, onClose, farmer }: Props) {
  if (!farmer) return null;

  const digitalTwin = farmer.digital_twin || {};
  const location = digitalTwin.location || {};
  const landSize = digitalTwin.land_size || {};
  const water = digitalTwin.water || {};
  const cropsData = digitalTwin.crops || {};
  const cropsList = cropsData.crops || [];

  return (
    <Drawer
      open={open}
      onClose={onClose}
      anchor="right"
      slotProps={{
        backdrop: { invisible: false },
        paper: {
          sx: { width: { xs: '100%', sm: 520, md: 600 }, p: 0 },
        },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          p: 3,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          borderBottom: (theme) => `1px solid ${theme.palette.divider}`,
          bgcolor: 'background.neutral',
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar
            sx={{
              width: 52,
              height: 52,
              bgcolor: 'primary.main',
              fontSize: '1.25rem',
              fontWeight: 700,
            }}
          >
            {farmer.full_name?.charAt(0).toUpperCase() || 'F'}
          </Avatar>
          <Box>
            <Typography variant="h6">{farmer.full_name}</Typography>
            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
              Farmer ID: {farmer.id || farmer._id}
            </Typography>
          </Box>
        </Box>

        <IconButton onClick={onClose} edge="end">
          <Iconify icon="mingcute:close-line" width={24} />
        </IconButton>
      </Box>

      {/* Content */}
      <Box sx={{ p: 3, overflowY: 'auto', flex: 1 }}>
        <Stack spacing={3}>
          {/* Status & Profile Completion Badges */}
          <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap' }}>
            <Chip
              label={farmer.status.toUpperCase()}
              color={farmer.status === 'active' ? 'success' : 'error'}
              variant="filled"
              size="small"
              sx={{ fontWeight: 600 }}
            />
            <Chip
              label={farmer.profile_completed ? 'Digital Twin Verified' : 'Profile Pending'}
              color={farmer.profile_completed ? 'primary' : 'warning'}
              variant="outlined"
              size="small"
              icon={
                <Iconify
                  icon={
                    farmer.profile_completed
                      ? 'solar:check-circle-bold'
                      : 'solar:clock-circle-bold'
                  }
                />
              }
            />
            {farmer.preferred_language && (
              <Chip
                label={`Language: ${farmer.preferred_language.toUpperCase()}`}
                size="small"
                variant="outlined"
              />
            )}
          </Box>

          {/* Personal Information */}
          <Card variant="outlined" sx={{ p: 2.5, borderRadius: 2 }}>
            <Typography variant="subtitle1" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
              <Iconify icon="solar:user-id-bold-duotone" width={22} sx={{ color: 'primary.main' }} />
              Farmer Contact Information
            </Typography>

            <Grid container spacing={2}>
              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block' }}>
                  Email Address
                </Typography>
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  {farmer.email || 'N/A'}
                </Typography>
              </Grid>

              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block' }}>
                  Phone Number
                </Typography>
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  {farmer.phone_number || 'N/A'}
                </Typography>
              </Grid>

              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block' }}>
                  Registered Date
                </Typography>
                <Typography variant="body2">
                  {farmer.created_at ? dayjs(farmer.created_at).format('DD MMM YYYY, hh:mm A') : 'N/A'}
                </Typography>
              </Grid>

              <Grid size={{ xs: 12, sm: 6 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block' }}>
                  Auth Provider
                </Typography>
                <Typography variant="body2" sx={{ textTransform: 'capitalize' }}>
                  {farmer.provider || 'Email / Direct'}
                </Typography>
              </Grid>
            </Grid>
          </Card>

          {/* Digital Twin Profile */}
          <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Iconify icon="fluent:leaf-three-16-filled" width={24} sx={{ color: 'success.main' }} />
            Digital Twin & Farm Specifications
          </Typography>

          {/* Location & Geography */}
          <Card variant="outlined" sx={{ p: 2.5, borderRadius: 2 }}>
            <Typography variant="subtitle2" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
              <Iconify icon="solar:map-point-bold-duotone" width={20} sx={{ color: 'primary.main' }} />
              Location & Jurisdiction
            </Typography>

            <Grid container spacing={2}>
              <Grid size={{ xs: 6, sm: 3 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  State
                </Typography>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  {location.state || 'Not specified'}
                </Typography>
              </Grid>
              <Grid size={{ xs: 6, sm: 3 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  District
                </Typography>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  {location.district || 'Not specified'}
                </Typography>
              </Grid>
              <Grid size={{ xs: 6, sm: 3 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  Taluk / Block
                </Typography>
                <Typography variant="body2">
                  {location.taluk || 'Not specified'}
                </Typography>
              </Grid>
              <Grid size={{ xs: 6, sm: 3 }}>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  Village
                </Typography>
                <Typography variant="body2">
                  {location.village || 'Not specified'}
                </Typography>
              </Grid>

              {(location.latitude != null && location.longitude != null) && (
                <Grid size={{ xs: 12 }}>
                  <Divider sx={{ my: 1, borderStyle: 'dashed' }} />
                  <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block' }}>
                    GPS Coordinates
                  </Typography>
                  <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                    Lat: {location.latitude}, Lng: {location.longitude}
                  </Typography>
                </Grid>
              )}
            </Grid>
          </Card>

          {/* Land Holdings & Water Resources */}
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <Card variant="outlined" sx={{ p: 2, borderRadius: 2, height: '100%' }}>
                <Typography variant="subtitle2" sx={{ mb: 1.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Iconify icon="solar:ruler-bold-duotone" width={20} sx={{ color: 'warning.main' }} />
                  Land Size
                </Typography>
                <Typography variant="h5" sx={{ color: 'primary.main', fontWeight: 700 }}>
                  {landSize.size_value != null ? landSize.size_value : '—'}
                  <Typography component="span" variant="subtitle2" sx={{ color: 'text.secondary', ml: 0.5 }}>
                    {landSize.unit || 'Acres'}
                  </Typography>
                </Typography>
              </Card>
            </Grid>

            <Grid size={{ xs: 12, sm: 6 }}>
              <Card variant="outlined" sx={{ p: 2, borderRadius: 2, height: '100%' }}>
                <Typography variant="subtitle2" sx={{ mb: 1.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Iconify icon="solar:waterdrops-bold-duotone" width={20} sx={{ color: 'info.main' }} />
                  Water Sources
                </Typography>
                <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
                  {water.sources && water.sources.length > 0 ? (
                    water.sources.map((src: string) => (
                      <Chip key={src} label={src} size="small" variant="outlined" color="info" />
                    ))
                  ) : (
                    <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                      None recorded
                    </Typography>
                  )}
                </Box>
              </Card>
            </Grid>
          </Grid>

          {/* Cultivated Crops */}
          <Card variant="outlined" sx={{ p: 2.5, borderRadius: 2 }}>
            <Typography variant="subtitle2" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
              <Iconify icon="solar:sprout-bold-duotone" width={20} sx={{ color: 'success.main' }} />
              Crops Under Cultivation
            </Typography>

            <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: cropsData.additional_notes ? 2 : 0 }}>
              {cropsList.length > 0 ? (
                cropsList.map((crop: string) => (
                  <Chip
                    key={crop}
                    label={crop}
                    color="success"
                    variant="filled"
                    sx={{ fontWeight: 600 }}
                  />
                ))
              ) : (
                <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                  No crops specified
                </Typography>
              )}
            </Box>

            {cropsData.additional_notes && (
              <>
                <Divider sx={{ my: 1.5, borderStyle: 'dashed' }} />
                <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mb: 0.5 }}>
                  Agronomic / Soil Notes
                </Typography>
                <Typography variant="body2" sx={{ fontStyle: 'italic', color: 'text.secondary' }}>
                  &ldquo;{cropsData.additional_notes}&rdquo;
                </Typography>
              </>
            )}
          </Card>
        </Stack>
      </Box>
    </Drawer>
  );
}
