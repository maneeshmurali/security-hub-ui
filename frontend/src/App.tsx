import React, { useEffect, useMemo, useState } from 'react';
import {
  AppBar,
  Box,
  Container,
  Toolbar,
  Typography,
  IconButton,
  Grid,
  Paper,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Stack,
  CircularProgress
} from '@mui/material';
import SettingsIcon from '@mui/icons-material/Settings';
import ShieldIcon from '@mui/icons-material/Shield';
import StatsCards from './components/StatsCards';
import ControlsTable from './components/ControlsTable';
import { fetchControls, fetchStats } from './api';

export type Control = {
  control_id: string;
  title: string;
  severity?: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW' | 'INFORMATIONAL' | string;
  affected_resources: number;
  regions: string[];
  products: string[];
};

export type Stats = {
  total_findings: number;
  severity_distribution: Record<string, number>;
  status_distribution: Record<string, number>;
  workflow_distribution: Record<string, number>;
};

function App() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [controls, setControls] = useState<Control[]>([]);
  const [loading, setLoading] = useState(true);
  const [severity, setSeverity] = useState<string>('');

  const totals = useMemo(() => {
    const totalControls = controls.length;
    const critical = controls.filter(c => c.severity === 'CRITICAL').length;
    const high = controls.filter(c => c.severity === 'HIGH').length;
    const affected = controls.reduce((sum, c) => sum + (c.affected_resources || 0), 0);
    return { totalControls, critical, high, affected };
  }, [controls]);

  useEffect(() => {
    let isMounted = true;
    setLoading(true);

    Promise.all([
      fetchStats(),
      fetchControls({ severity: severity || undefined })
    ]).then(([statsData, controlsData]) => {
      if (!isMounted) return;
      setStats(statsData);
      setControls(controlsData.controls || []);
    }).finally(() => {
      if (isMounted) setLoading(false);
    });

    return () => { isMounted = false; };
  }, [severity]);

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      <AppBar position="static">
        <Toolbar>
          <ShieldIcon sx={{ mr: 1 }} />
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            AWS Security Hub Dashboard
          </Typography>
          <IconButton color="inherit"><SettingsIcon /></IconButton>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <StatsCards
              totalControls={totals.totalControls}
              criticalControls={totals.critical}
              highControls={totals.high}
              affectedResources={totals.affected}
            />
          </Grid>

          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center" justifyContent="space-between">
                <Typography variant="h6">Security Controls</Typography>
                <FormControl size="small" sx={{ minWidth: 200 }}>
                  <InputLabel id="severity-label">Severity</InputLabel>
                  <Select
                    labelId="severity-label"
                    value={severity}
                    label="Severity"
                    onChange={(e) => setSeverity(e.target.value)}
                  >
                    <MenuItem value="">All Severities</MenuItem>
                    <MenuItem value="CRITICAL">Critical</MenuItem>
                    <MenuItem value="HIGH">High</MenuItem>
                    <MenuItem value="MEDIUM">Medium</MenuItem>
                    <MenuItem value="LOW">Low</MenuItem>
                    <MenuItem value="INFORMATIONAL">Informational</MenuItem>
                  </Select>
                </FormControl>
              </Stack>

              {loading ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
                  <CircularProgress />
                </Box>
              ) : (
                <ControlsTable controls={controls} />
              )}
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}

export default App;