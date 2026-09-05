import { useMemo, useState } from 'react';

import Box from '@mui/material/Box';
import Tab from '@mui/material/Tab';
import Card from '@mui/material/Card';
import Grid from '@mui/material/Grid';
import Chip from '@mui/material/Chip';
import Tabs from '@mui/material/Tabs';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import Typography from '@mui/material/Typography';
import CardContent from '@mui/material/CardContent';
import DialogTitle from '@mui/material/DialogTitle';
import OutlinedInput from '@mui/material/OutlinedInput';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import InputAdornment from '@mui/material/InputAdornment';

import { DashboardContent } from 'src/layouts/dashboard';

import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

type AdvisoryItem = {
  id: string;
  title: string;
  category: 'scheme' | 'pest' | 'weather' | 'soil';
  categoryLabel: string;
  targetCrops?: string[];
  summary: string;
  details: string;
  validTill?: string;
  authority: string;
  badgeColor: 'primary' | 'success' | 'warning' | 'info';
};

const ADVISORIES_DATA: AdvisoryItem[] = [
  {
    id: 'adv-1',
    title: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
    category: 'scheme',
    categoryLabel: 'Govt Scheme',
    authority: 'Ministry of Agriculture & Farmers Welfare',
    badgeColor: 'primary',
    validTill: 'Active / Ongoing',
    summary: 'Direct income support of ₹6,000 per year in three equal installments to all landholding farmer families.',
    details:
      'Under PM-KISAN, financial assistance of ₹6,000/year is transferred directly into Aadhaar-seeded bank accounts of beneficiary farmers. Ensure farmers have completed e-KYC and updated land records in the Krushi Setu Digital Twin.',
  },
  {
    id: 'adv-2',
    title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
    category: 'scheme',
    categoryLabel: 'Crop Insurance',
    authority: 'Government of India',
    badgeColor: 'info',
    validTill: 'Enrollment Open',
    summary: 'Comprehensive crop insurance coverage against non-preventable natural risks from pre-sowing to post-harvest.',
    details:
      'Covers financial loss suffered due to natural calamities like drought, flood, pests, and diseases. Farmers pay a nominal premium: 2% for Kharif crops, 1.5% for Rabi crops, and 5% for commercial/horticultural crops.',
  },
  {
    id: 'adv-3',
    title: 'Kharif Paddy: Blast & Stem Borer Management',
    category: 'pest',
    categoryLabel: 'Pest Alert',
    targetCrops: ['Paddy (Rice)'],
    authority: 'ICAR - Indian Agricultural Research Institute',
    badgeColor: 'error' as any,
    validTill: 'Current Season',
    summary: 'High humidity and cloudy weather increase blast disease incidence in early-tillering paddy.',
    details:
      'Monitor for spindle-shaped lesions on leaves with brown margins. Spray Tricyclazole 75% WP @ 0.6g/L or Isoprothiolane 40% EC @ 1.5ml/L of water. For stem borer, set up pheromone traps @ 5/acre.',
  },
  {
    id: 'adv-4',
    title: 'Soil Health Card & Micronutrient Optimization',
    category: 'soil',
    categoryLabel: 'Soil Health',
    authority: 'Department of Agriculture',
    badgeColor: 'success',
    validTill: 'Year-round',
    summary: 'Soil testing guidelines for optimal NPK balance and correction of Zinc & Boron deficiencies.',
    details:
      'Regular soil testing prevents fertilizer over-application and reduces input costs by up to 25%. Encourage farmers to follow customized fertilizer recommendations based on Digital Twin soil data.',
  },
  {
    id: 'adv-5',
    title: 'Heavy Rainfall & Waterlogging Alert - Southern Deccan Region',
    category: 'weather',
    categoryLabel: 'Weather Alert',
    authority: 'India Meteorological Department (IMD)',
    badgeColor: 'warning',
    validTill: 'Next 5 Days',
    summary: 'Moderate to heavy showers expected across Dharwad, Belagavi, and Shimoga districts.',
    details:
      'Ensure adequate drainage channels in cotton, groundnut, and vegetable fields to prevent root rot. Delay top dressing of urea until rain subsides.',
  },
  {
    id: 'adv-6',
    title: 'Pradhan Mantri Krishi Sinchayee Yojana (Micro Irrigation)',
    category: 'scheme',
    categoryLabel: 'Govt Scheme',
    authority: 'Ministry of Jal Shakti',
    badgeColor: 'primary',
    validTill: 'Active',
    summary: 'Subsidies up to 55% for small/marginal farmers for installing Drip and Sprinkler irrigation systems.',
    details:
      'Increases water use efficiency up to 90% and optimizes crop yield. Applications can be initiated with land records and water source verification from the Digital Twin.',
  },
];

export function AdvisoryView() {
  const [currentTab, setCurrentTab] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedItem, setSelectedItem] = useState<AdvisoryItem | null>(null);

  const filteredAdvisories = useMemo(() => ADVISORIES_DATA.filter((item) => {
      const matchesTab = currentTab === 'all' || item.category === currentTab;
      const matchesSearch =
        item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.summary.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.authority.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }), [currentTab, searchQuery]);

  return (
    <DashboardContent>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>
          Agricultural Advisory & Schemes
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
          Government subsidies, seasonal pest alerts, weather updates, and farming best practices for farmers
        </Typography>
      </Box>

      {/* Filter & Search Bar */}
      <Card sx={{ p: 2, mb: 3 }}>
        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 2, alignItems: { md: 'center' }, justifyContent: 'space-between' }}>
          <Tabs
            value={currentTab}
            onChange={(e, val) => setCurrentTab(val)}
            variant="scrollable"
            scrollButtons="auto"
          >
            <Tab value="all" label="All Advisories" />
            <Tab value="scheme" label="Government Schemes" />
            <Tab value="pest" label="Pest & Disease Alerts" />
            <Tab value="weather" label="Weather Bulletins" />
            <Tab value="soil" label="Soil Health" />
          </Tabs>

          <OutlinedInput
            size="small"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search schemes or advisories..."
            startAdornment={
              <InputAdornment position="start">
                <Iconify width={18} icon="eva:search-fill" sx={{ color: 'text.disabled' }} />
              </InputAdornment>
            }
            sx={{ minWidth: 260 }}
          />
        </Box>
      </Card>

      {/* Grid of Advisory Cards */}
      <Grid container spacing={3}>
        {filteredAdvisories.map((item) => (
          <Grid key={item.id} size={{ xs: 12, sm: 6, md: 4 }}>
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
              <CardContent sx={{ flex: 1, p: 3, display: 'flex', flexDirection: 'column' }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1.5 }}>
                  <Chip
                    label={item.categoryLabel}
                    color={item.badgeColor}
                    size="small"
                    sx={{ fontWeight: 600, fontSize: '0.75rem' }}
                  />
                  {item.validTill && (
                    <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500 }}>
                      {item.validTill}
                    </Typography>
                  )}
                </Box>

                <Typography variant="h6" sx={{ fontWeight: 700, mb: 1, minHeight: 48, lineHeight: 1.3 }}>
                  {item.title}
                </Typography>

                <Typography variant="body2" sx={{ color: 'text.secondary', mb: 2, flex: 1, lineHeight: 1.5 }}>
                  {item.summary}
                </Typography>

                {item.targetCrops && (
                  <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 2 }}>
                    {item.targetCrops.map((c) => (
                      <Chip key={c} label={c} size="small" variant="outlined" sx={{ fontSize: '0.7rem' }} />
                    ))}
                  </Box>
                )}

                <Box sx={{ pt: 1.5, borderTop: (theme) => `1px dashed ${theme.palette.divider}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="caption" sx={{ color: 'text.disabled', maxWidth: '65%' }} noWrap>
                    {item.authority}
                  </Typography>
                  <Button
                    size="small"
                    color="primary"
                    variant="text"
                    onClick={() => setSelectedItem(item)}
                    endIcon={<Iconify icon="eva:arrow-ios-forward-fill" />}
                  >
                    View Details
                  </Button>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}

        {filteredAdvisories.length === 0 && (
          <Grid size={{ xs: 12 }}>
            <Box sx={{ p: 5, textAlign: 'center', bgcolor: 'background.neutral', borderRadius: 2 }}>
              <Typography variant="subtitle1" sx={{ color: 'text.secondary' }}>
                No advisories found matching &ldquo;{searchQuery}&rdquo;.
              </Typography>
            </Box>
          </Grid>
        )}
      </Grid>

      {/* Advisory Detail Dialog */}
      <Dialog
        open={!!selectedItem}
        onClose={() => setSelectedItem(null)}
        maxWidth="sm"
        fullWidth
      >
        {selectedItem && (
          <>
            <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <Box>
                <Chip
                  label={selectedItem.categoryLabel}
                  color={selectedItem.badgeColor}
                  size="small"
                  sx={{ fontWeight: 600, mb: 1 }}
                />
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {selectedItem.title}
                </Typography>
                <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mt: 0.5 }}>
                  Issued by: {selectedItem.authority}
                </Typography>
              </Box>
            </DialogTitle>
            <DialogContent dividers>
              <Typography variant="subtitle2" sx={{ color: 'text.secondary', mb: 1 }}>
                Overview:
              </Typography>
              <Typography variant="body1" sx={{ mb: 3 }}>
                {selectedItem.summary}
              </Typography>

              <Typography variant="subtitle2" sx={{ color: 'text.secondary', mb: 1 }}>
                Actionable Guidance & Implementation:
              </Typography>
              <Typography variant="body2" sx={{ lineHeight: 1.7, bgcolor: 'background.neutral', p: 2, borderRadius: 1.5 }}>
                {selectedItem.details}
              </Typography>
            </DialogContent>
            <DialogActions sx={{ p: 2 }}>
              <Button onClick={() => setSelectedItem(null)} color="primary" variant="contained">
                Close
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </DashboardContent>
  );
}
