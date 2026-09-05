import type { Farmer } from 'src/services/api';

import dayjs from 'dayjs';
import { useState, useCallback } from 'react';

import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Avatar from '@mui/material/Avatar';
import Popover from '@mui/material/Popover';
import Tooltip from '@mui/material/Tooltip';
import TableRow from '@mui/material/TableRow';
import Checkbox from '@mui/material/Checkbox';
import MenuList from '@mui/material/MenuList';
import TableCell from '@mui/material/TableCell';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import MenuItem, { menuItemClasses } from '@mui/material/MenuItem';

import { Label } from 'src/components/label';
import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

type UserTableRowProps = {
  row: Farmer;
  selected: boolean;
  onSelectRow: () => void;
  onViewDetails: (farmer: Farmer) => void;
  onToggleStatus: (farmer: Farmer) => void;
  onDelete: (farmer: Farmer) => void;
};

export function UserTableRow({
  row,
  selected,
  onSelectRow,
  onViewDetails,
  onToggleStatus,
  onDelete,
}: UserTableRowProps) {
  const [openPopover, setOpenPopover] = useState<HTMLButtonElement | null>(null);

  const handleOpenPopover = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    setOpenPopover(event.currentTarget);
  }, []);

  const handleClosePopover = useCallback(() => {
    setOpenPopover(null);
  }, []);

  const dt = row.digital_twin || {};
  const location = dt.location || {};
  const cropsList = dt.crops?.crops || [];
  const locationText = location.district
    ? `${location.district}, ${location.state || ''}`
    : location.state || '—';

  return (
    <>
      <TableRow hover tabIndex={-1} role="checkbox" selected={selected}>
        <TableCell padding="checkbox">
          <Checkbox disableRipple checked={selected} onChange={onSelectRow} />
        </TableCell>

        {/* Farmer Name & Contact */}
        <TableCell component="th" scope="row">
          <Box
            sx={{
              gap: 2,
              display: 'flex',
              alignItems: 'center',
              cursor: 'pointer',
            }}
            onClick={() => onViewDetails(row)}
          >
            <Avatar
              sx={{
                bgcolor: 'primary.lighter',
                color: 'primary.dark',
                fontWeight: 700,
              }}
            >
              {row.full_name?.charAt(0).toUpperCase() || 'F'}
            </Avatar>
            <Box>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, '&:hover': { color: 'primary.main' } }}>
                {row.full_name}
              </Typography>
              <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block' }}>
                {row.phone_number || row.email}
              </Typography>
            </Box>
          </Box>
        </TableCell>

        {/* Location */}
        <TableCell>{locationText}</TableCell>

        {/* Crops */}
        <TableCell>
          <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', maxWidth: 220 }}>
            {cropsList.length > 0 ? (
              cropsList.slice(0, 2).map((crop) => (
                <Chip key={crop} label={crop} size="small" variant="outlined" sx={{ fontSize: '0.7rem' }} />
              ))
            ) : (
              <Typography variant="caption" sx={{ color: 'text.disabled' }}>
                No crops listed
              </Typography>
            )}
            {cropsList.length > 2 && (
              <Chip
                label={`+${cropsList.length - 2}`}
                size="small"
                sx={{ fontSize: '0.7rem', height: 20 }}
              />
            )}
          </Box>
        </TableCell>

        {/* Digital Twin Profile Completed */}
        <TableCell align="center">
          {row.profile_completed ? (
            <Tooltip title="Digital Twin Profile Completed">
              <Chip
                label="Completed"
                size="small"
                color="success"
                variant="filled"
                icon={<Iconify width={16} icon="solar:check-circle-bold" />}
              />
            </Tooltip>
          ) : (
            <Chip label="Pending" size="small" variant="outlined" color="warning" />
          )}
        </TableCell>

        {/* Account Status */}
        <TableCell>
          <Label color={(row.status === 'banned' && 'error') || 'success'}>
            {row.status}
          </Label>
        </TableCell>

        {/* Joined Date */}
        <TableCell sx={{ color: 'text.secondary', fontSize: '0.8rem' }}>
          {row.created_at ? dayjs(row.created_at).format('DD MMM YYYY') : '—'}
        </TableCell>

        {/* Actions */}
        <TableCell align="right">
          <IconButton onClick={handleOpenPopover}>
            <Iconify icon="eva:more-vertical-fill" />
          </IconButton>
        </TableCell>
      </TableRow>

      <Popover
        open={!!openPopover}
        anchorEl={openPopover}
        onClose={handleClosePopover}
        anchorOrigin={{ vertical: 'top', horizontal: 'left' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <MenuList
          disablePadding
          sx={{
            p: 0.5,
            gap: 0.5,
            width: 170,
            display: 'flex',
            flexDirection: 'column',
            [`& .${menuItemClasses.root}`]: {
              px: 1,
              gap: 2,
              borderRadius: 0.75,
              fontSize: '0.85rem',
              [`&.${menuItemClasses.selected}`]: { bgcolor: 'action.selected' },
            },
          }}
        >
          <MenuItem
            onClick={() => {
              handleClosePopover();
              onViewDetails(row);
            }}
          >
            <Iconify icon="solar:eye-bold" />
            View Digital Twin
          </MenuItem>

          <MenuItem
            onClick={() => {
              handleClosePopover();
              onToggleStatus(row);
            }}
          >
            <Iconify
              icon={row.status === 'active' ? 'solar:user-block-bold' : 'solar:user-check-bold'}
              sx={{ color: row.status === 'active' ? 'warning.main' : 'success.main' }}
            />
            {row.status === 'active' ? 'Ban Farmer' : 'Activate Farmer'}
          </MenuItem>

          <MenuItem
            onClick={() => {
              handleClosePopover();
              onDelete(row);
            }}
            sx={{ color: 'error.main' }}
          >
            <Iconify icon="solar:trash-bin-trash-bold" />
            Delete Account
          </MenuItem>
        </MenuList>
      </Popover>
    </>
  );
}

