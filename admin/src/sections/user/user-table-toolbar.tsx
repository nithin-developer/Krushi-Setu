import type { SelectChangeEvent } from '@mui/material/Select';

import Box from '@mui/material/Box';
import Select from '@mui/material/Select';
import Toolbar from '@mui/material/Toolbar';
import MenuItem from '@mui/material/MenuItem';
import Typography from '@mui/material/Typography';
import InputLabel from '@mui/material/InputLabel';
import FormControl from '@mui/material/FormControl';
import OutlinedInput from '@mui/material/OutlinedInput';
import InputAdornment from '@mui/material/InputAdornment';

import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

type UserTableToolbarProps = {
  numSelected: number;
  filterName: string;
  statusFilter: string;
  onFilterName: (event: React.ChangeEvent<HTMLInputElement>) => void;
  onStatusFilterChange: (event: SelectChangeEvent<string>) => void;
};

export function UserTableToolbar({
  numSelected,
  filterName,
  statusFilter,
  onFilterName,
  onStatusFilterChange,
}: UserTableToolbarProps) {
  return (
    <Toolbar
      sx={{
        height: 88,
        display: 'flex',
        justifyContent: 'space-between',
        p: (theme) => theme.spacing(0, 2, 0, 3),
        gap: 2,
        ...(numSelected > 0 && {
          color: 'primary.main',
          bgcolor: 'primary.lighter',
        }),
      }}
    >
      {numSelected > 0 ? (
        <Typography component="div" variant="subtitle1">
          {numSelected} selected
        </Typography>
      ) : (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flex: 1, flexWrap: 'wrap' }}>
          <OutlinedInput
            value={filterName}
            onChange={onFilterName}
            placeholder="Search farmers by name, phone, email..."
            startAdornment={
              <InputAdornment position="start">
                <Iconify width={20} icon="eva:search-fill" sx={{ color: 'text.disabled' }} />
              </InputAdornment>
            }
            sx={{ width: { xs: 1, sm: 360 } }}
          />

          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel id="status-filter-label">Farmer Status</InputLabel>
            <Select
              labelId="status-filter-label"
              value={statusFilter}
              label="Farmer Status"
              onChange={onStatusFilterChange}
            >
              <MenuItem value="all">All Farmers</MenuItem>
              <MenuItem value="active">Active</MenuItem>
              <MenuItem value="banned">Banned</MenuItem>
            </Select>
          </FormControl>
        </Box>
      )}
    </Toolbar>
  );
}

