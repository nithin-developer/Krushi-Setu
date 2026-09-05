import { useState, useCallback } from 'react';

import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import InputAdornment from '@mui/material/InputAdornment';
import CircularProgress from '@mui/material/CircularProgress';

import { useRouter } from 'src/routes/hooks';

import { useAuth } from 'src/auth';

import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

export function SignInView() {
  const router = useRouter();
  const { login } = useAuth();

  const [email, setEmail] = useState('admin@krushisetu.com');
  const [password, setPassword] = useState('Admin@123');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const handleSignIn = useCallback(
    async (event: React.FormEvent) => {
      event.preventDefault();
      if (!email.trim() || !password.trim()) {
        setErrorMessage('Please enter both email and password.');
        return;
      }

      setIsLoading(true);
      setErrorMessage('');

      try {
        await login(email.trim(), password);
        router.push('/');
      } catch (err: any) {
        const detail =
          err.response?.data?.detail ||
          err.message ||
          'Failed to sign in. Please verify your credentials.';
        setErrorMessage(detail);
      } finally {
        setIsLoading(false);
      }
    },
    [email, password, login, router]
  );

  const fillDefaultCredentials = (e: string, p: string) => {
    setEmail(e);
    setPassword(p);
    setErrorMessage('');
  };

  return (
    <>
      <Box
        sx={{
          gap: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          mb: 4,
          textAlign: 'center',
        }}
      >
        <Box
          sx={{
            width: 56,
            height: 56,
            borderRadius: 2,
            bgcolor: 'primary.lighter',
            color: 'primary.main',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            mb: 1,
          }}
        >
          <Iconify icon="fluent:leaf-three-16-filled" width={32} />
        </Box>

        <Typography variant="h4" sx={{ fontWeight: 700 }}>
          Krushi Setu
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary' }}>
          Administrator & Operations Control Portal
        </Typography>
      </Box>

      {errorMessage && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {errorMessage}
        </Alert>
      )}

      <Box component="form" onSubmit={handleSignIn} sx={{ display: 'flex', flexDirection: 'column' }}>
        <TextField
          fullWidth
          name="email"
          label="Admin Email address"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={isLoading}
          autoComplete="username"
          sx={{ mb: 3 }}
          slotProps={{
            inputLabel: { shrink: true },
          }}
        />

        <TextField
          fullWidth
          name="password"
          label="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          disabled={isLoading}
          autoComplete="current-password"
          type={showPassword ? 'text' : 'password'}
          slotProps={{
            inputLabel: { shrink: true },
            input: {
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton onClick={() => setShowPassword(!showPassword)} edge="end">
                    <Iconify icon={showPassword ? 'solar:eye-bold' : 'solar:eye-closed-bold'} />
                  </IconButton>
                </InputAdornment>
              ),
            },
          }}
          sx={{ mb: 3 }}
        />

        <Button
          fullWidth
          size="large"
          type="submit"
          color="primary"
          variant="contained"
          disabled={isLoading}
          sx={{ py: 1.5, fontWeight: 700 }}
          startIcon={isLoading ? <CircularProgress size={20} color="inherit" /> : null}
        >
          {isLoading ? 'Authenticating...' : 'Sign in to Admin Portal'}
        </Button>
      </Box>

      <Box
        sx={{
          mt: 4,
          p: 2,
          borderRadius: 1.5,
          bgcolor: 'background.neutral',
          border: (theme) => `1px dashed ${theme.palette.divider}`,
          textAlign: 'center',
        }}
      >
        <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mb: 1 }}>
          Initial Super Admin Credentials (Click to load):
        </Typography>
        <Chip
          label="admin@krushisetu.com / Admin@123"
          size="small"
          onClick={() => fillDefaultCredentials('admin@krushisetu.com', 'Admin@123')}
          icon={<Iconify icon="solar:shield-keyhole-bold" width={16} />}
          sx={{ cursor: 'pointer', fontFamily: 'monospace', fontSize: '0.75rem' }}
        />
      </Box>
    </>
  );
}

