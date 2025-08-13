import React, { useMemo, useState } from 'react';
import {
  Box,
  Chip,
  Divider,
  Drawer,
  IconButton,
  Link,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography
} from '@mui/material';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import CloseIcon from '@mui/icons-material/Close';
import { fetchControlDetails } from '../api';
import type { Control } from '../App';

function SeverityChip({ value }: { value?: string }) {
  const color = useMemo(() => {
    switch (value) {
      case 'CRITICAL': return 'error';
      case 'HIGH': return 'warning';
      case 'MEDIUM': return 'secondary';
      case 'LOW': return 'success';
      default: return 'default';
    }
  }, [value]);
  return <Chip label={value || 'UNKNOWN'} color={color as any} size="small" />;
}

export default function ControlsTable({ controls }: { controls: Control[] }) {
  const [open, setOpen] = useState(false);
  const [details, setDetails] = useState<any | null>(null);

  const onOpenDetails = async (controlId: string) => {
    const data = await fetchControlDetails(controlId);
    setDetails(data);
    setOpen(true);
  };

  return (
    <>
      <TableContainer>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Control ID</TableCell>
              <TableCell>Title</TableCell>
              <TableCell>Severity</TableCell>
              <TableCell align="right">Affected Resources</TableCell>
              <TableCell>Regions</TableCell>
              <TableCell>Products</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {controls.map((c) => (
              <TableRow key={c.control_id} hover sx={{ cursor: 'pointer' }} onClick={() => onOpenDetails(c.control_id)}>
                <TableCell><Chip label={c.control_id} size="small" /></TableCell>
                <TableCell sx={{ maxWidth: 420 }}>
                  <Typography noWrap title={c.title}>{c.title}</Typography>
                </TableCell>
                <TableCell><SeverityChip value={c.severity} /></TableCell>
                <TableCell align="right">{c.affected_resources}</TableCell>
                <TableCell>
                  <Stack direction="row" spacing={0.5} flexWrap="wrap">
                    {c.regions.slice(0, 3).map(r => <Chip key={r} label={r} size="small" />)}
                    {c.regions.length > 3 && <Chip label={`+${c.regions.length - 3}`} size="small" />}
                  </Stack>
                </TableCell>
                <TableCell>
                  <Stack direction="row" spacing={0.5} flexWrap="wrap">
                    {c.products.slice(0, 2).map(p => <Chip key={p} label={p} size="small" color="info" />)}
                    {c.products.length > 2 && <Chip label={`+${c.products.length - 2}`} size="small" />}
                  </Stack>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Drawer anchor="right" open={open} onClose={() => setOpen(false)} PaperProps={{ sx: { width: { xs: '100%', sm: 560 } } }}>
        <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ p: 2 }}>
          <Typography variant="h6">Control Details</Typography>
          <IconButton onClick={() => setOpen(false)}><CloseIcon /></IconButton>
        </Stack>
        <Divider />
        <Box sx={{ p: 2 }}>
          {!details ? (
            <Typography color="text.secondary">Loading...</Typography>
          ) : (
            <Stack spacing={2}>
              <Stack direction="row" spacing={1} alignItems="center">
                <Chip label={details?.control?.control_id} />
                <SeverityChip value={details?.control?.severity} />
              </Stack>
              <Typography variant="subtitle1">{details?.control?.title}</Typography>
              <Typography variant="body2" color="text.secondary">{details?.control?.description}</Typography>
              <Divider />
              <Typography variant="subtitle2">Affected Resources: {details?.total_affected_resources}</Typography>
              <Typography variant="subtitle2">Regions</Typography>
              <Stack direction="row" spacing={0.5} flexWrap="wrap">
                {(details?.control?.regions || details?.regions || []).slice(0, 10).map((r: string) => (
                  <Chip key={r} label={r} size="small" />
                ))}
              </Stack>
              <Typography variant="subtitle2">Products</Typography>
              <Stack direction="row" spacing={0.5} flexWrap="wrap">
                {(details?.control?.products || details?.products || []).slice(0, 10).map((p: string) => (
                  <Chip key={p} label={p} size="small" color="info" />
                ))}
              </Stack>
              <Divider />
              <Stack direction="row" spacing={1}>
                <Link href="#" onClick={(e) => e.preventDefault()} underline="hover">
                  Export CSV
                </Link>
                <Link href="#" onClick={(e) => e.preventDefault()} underline="hover">
                  Export JSON
                </Link>
                <IconButton size="small" title="Open in new">
                  <OpenInNewIcon fontSize="small" />
                </IconButton>
              </Stack>
            </Stack>
          )}
        </Box>
      </Drawer>
    </>
  );
}