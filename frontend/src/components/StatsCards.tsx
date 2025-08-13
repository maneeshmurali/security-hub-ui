import React from 'react';
import { Grid, Paper, Stack, Typography } from '@mui/material';
import ShieldIcon from '@mui/icons-material/Shield';
import ReportIcon from '@mui/icons-material/Report';
import PriorityHighIcon from '@mui/icons-material/PriorityHigh';
import StorageIcon from '@mui/icons-material/Storage';

interface Props {
  totalControls: number;
  criticalControls: number;
  highControls: number;
  affectedResources: number;
}

function StatCard({ title, value, icon }: { title: string; value: number | string; icon: React.ReactNode }) {
  return (
    <Paper sx={{ p: 2 }}>
      <Stack direction="row" spacing={2} alignItems="center">
        {icon}
        <div>
          <Typography variant="h5" fontWeight={700}>{value}</Typography>
          <Typography variant="body2" color="text.secondary">{title}</Typography>
        </div>
      </Stack>
    </Paper>
  );
}

export default function StatsCards({ totalControls, criticalControls, highControls, affectedResources }: Props) {
  return (
    <Grid container spacing={2}>
      <Grid item xs={12} sm={6} md={3}>
        <StatCard title="Security Controls" value={totalControls} icon={<ShieldIcon color="primary" />} />
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <StatCard title="Critical Controls" value={criticalControls} icon={<ReportIcon color="error" />} />
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <StatCard title="High Controls" value={highControls} icon={<PriorityHighIcon color="warning" />} />
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <StatCard title="Affected Resources" value={affectedResources} icon={<StorageIcon color="info" />} />
      </Grid>
    </Grid>
  );
}