// Security Hub Dashboard JavaScript

class SecurityHubDashboard {
    constructor() {
        this.currentPage = 0;
        this.pageSize = 50;
        this.totalFindings = 0;
        this.findings = [];
        this.products = [];
        this.accounts = [];
        this.regions = [];
        this.selectedFindings = new Set();
        this.filterPresets = [];
        this.settings = this.loadSettings();
        this.autoRefreshInterval = null;
        this.lastStats = {};
        this.init();
    }

    async init() {
        await this.loadStats();
        await this.loadProducts();
        await this.loadAccounts();
        await this.loadRegions();
        await this.loadFindings();
        await this.updateSchedulerStatus();
        this.setupEventListeners();
        this.setupAutoRefresh();
        this.loadFilterPresets();
        
        // Set up periodic updates
        setInterval(() => this.updateSchedulerStatus(), 30000); // Every 30 seconds
        setInterval(() => this.loadStats(), 60000); // Every minute
    }

    setupEventListeners() {
        // Page size change
        document.getElementById('page-size').addEventListener('change', (e) => {
            this.pageSize = parseInt(e.target.value);
            this.currentPage = 0;
            this.loadFindings();
        });

        // Auto-refresh toggle
        document.getElementById('auto-refresh').addEventListener('change', (e) => {
            if (e.target.checked) {
                this.setupAutoRefresh();
            } else {
                this.clearAutoRefresh();
            }
        });

        // Show descriptions toggle
        document.getElementById('show-descriptions').addEventListener('change', (e) => {
            this.renderFindings();
        });

        // Select all checkbox
        document.getElementById('select-all').addEventListener('change', (e) => {
            this.toggleSelectAll(e.target.checked);
        });

        // Header checkbox
        document.getElementById('header-checkbox').addEventListener('change', (e) => {
            this.toggleSelectAll(e.target.checked);
        });
    }

    setupAutoRefresh() {
        this.clearAutoRefresh();
        const interval = this.settings.autoRefreshInterval || 60;
        if (interval > 0) {
            this.autoRefreshInterval = setInterval(() => {
                this.loadFindings();
                this.loadStats();
            }, interval * 1000);
        }
    }

    clearAutoRefresh() {
        if (this.autoRefreshInterval) {
            clearInterval(this.autoRefreshInterval);
            this.autoRefreshInterval = null;
        }
    }

    loadSettings() {
        const defaultSettings = {
            autoRefreshInterval: 60,
            defaultPageSize: 50,
            showDescriptionsDefault: true,
            enableNotifications: true
        };
        
        try {
            const saved = localStorage.getItem('securityHubSettings');
            return saved ? { ...defaultSettings, ...JSON.parse(saved) } : defaultSettings;
        } catch (error) {
            console.error('Error loading settings:', error);
            return defaultSettings;
        }
    }

    saveSettings() {
        try {
            localStorage.setItem('securityHubSettings', JSON.stringify(this.settings));
        } catch (error) {
            console.error('Error saving settings:', error);
        }
    }

    loadFilterPresets() {
        try {
            const saved = localStorage.getItem('securityHubFilterPresets');
            this.filterPresets = saved ? JSON.parse(saved) : [];
        } catch (error) {
            console.error('Error loading filter presets:', error);
            this.filterPresets = [];
        }
    }

    saveFilterPresets() {
        try {
            localStorage.setItem('securityHubFilterPresets', JSON.stringify(this.filterPresets));
        } catch (error) {
            console.error('Error saving filter presets:', error);
        }
    }

    async loadStats() {
        try {
            const response = await fetch('/api/stats');
            const stats = await response.json();
            
            // Update stats with trend indicators
            this.updateStatWithTrend('total-findings', stats.total_findings, 'total-trend');
            this.updateStatWithTrend('critical-findings', stats.severity_distribution.CRITICAL || 0, 'critical-trend');
            this.updateStatWithTrend('high-findings', stats.severity_distribution.HIGH || 0, 'high-trend');
            this.updateStatWithTrend('medium-findings', stats.severity_distribution.MEDIUM || 0, 'medium-trend');
            this.updateStatWithTrend('active-findings', stats.status_distribution.ACTIVE || 0, 'active-trend');
            this.updateStatWithTrend('archived-findings', stats.status_distribution.ARCHIVED || 0, 'archived-trend');
            
            // Update last updated timestamp
            document.getElementById('last-updated').textContent = new Date().toLocaleTimeString();
            
            // Store for trend calculation
            this.lastStats = stats;
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    updateStatWithTrend(elementId, currentValue, trendId) {
        const element = document.getElementById(elementId);
        const trendElement = document.getElementById(trendId);
        
        if (element && trendElement) {
            const previousValue = this.lastStats[elementId] || 0;
            const change = currentValue - previousValue;
            const changePercent = previousValue > 0 ? ((change / previousValue) * 100).toFixed(1) : 0;
            
            element.textContent = currentValue;
            
            if (change > 0) {
                trendElement.textContent = `↗️ +${changePercent}%`;
                trendElement.className = 'stats-trend text-success';
            } else if (change < 0) {
                trendElement.textContent = `↘️ ${changePercent}%`;
                trendElement.className = 'stats-trend text-danger';
            } else {
                trendElement.textContent = `→ 0%`;
                trendElement.className = 'stats-trend text-muted';
            }
        }
    }

    async loadAccounts() {
        try {
            const response = await fetch('/api/findings?limit=1000');
            const findings = await response.json();
            
            const accounts = [...new Set(findings.map(f => f.aws_account_id).filter(a => a))];
            this.accounts = accounts.sort();
            
            const accountSelect = document.getElementById('account-filter');
            accountSelect.innerHTML = '<option value="">All Accounts</option>';
            
            accounts.forEach(account => {
                const option = document.createElement('option');
                option.value = account;
                option.textContent = account;
                accountSelect.appendChild(option);
            });
        } catch (error) {
            console.error('Error loading accounts:', error);
        }
    }

    async loadRegions() {
        try {
            const response = await fetch('/api/findings?limit=1000');
            const findings = await response.json();
            
            const regions = [...new Set(findings.map(f => f.region).filter(r => r))];
            this.regions = regions.sort();
            
            const regionSelect = document.getElementById('region-filter');
            regionSelect.innerHTML = '<option value="">All Regions</option>';
            
            regions.forEach(region => {
                const option = document.createElement('option');
                option.value = region;
                option.textContent = region;
                regionSelect.appendChild(option);
            });
        } catch (error) {
            console.error('Error loading regions:', error);
        }
    }

    async loadProducts() {
        try {
            const response = await fetch('/api/findings?limit=1000');
            const findings = await response.json();
            
            const products = [...new Set(findings.map(f => f.product_name).filter(p => p))];
            this.products = products.sort();
            
            const productSelect = document.getElementById('product-filter');
            productSelect.innerHTML = '<option value="">All Products</option>';
            
            products.forEach(product => {
                const option = document.createElement('option');
                option.value = product;
                option.textContent = product;
                productSelect.appendChild(option);
            });
        } catch (error) {
            console.error('Error loading products:', error);
        }
    }

    async loadFindings() {
        try {
            this.showLoading();
            
            const params = new URLSearchParams({
                limit: this.pageSize,
                offset: this.currentPage * this.pageSize
            });

            // Add filters
            const severity = document.getElementById('severity-filter').value;
            const status = document.getElementById('status-filter').value;
            const product = document.getElementById('product-filter').value;
            const startDate = document.getElementById('start-date').value;
            const endDate = document.getElementById('end-date').value;

            if (severity) params.append('severity', severity);
            if (status) params.append('status', status);
            if (product) params.append('product_name', product);
            if (startDate) params.append('start_date', startDate);
            if (endDate) params.append('end_date', endDate);

            const response = await fetch(`/api/findings?${params}`);
            this.findings = await response.json();
            
            this.renderFindings();
            this.updatePagination();
        } catch (error) {
            console.error('Error loading findings:', error);
            this.showError('Failed to load findings');
        }
    }

    renderFindings() {
        const tbody = document.getElementById('findings-tbody');
        const showDescriptions = document.getElementById('show-descriptions').checked;
        
        if (this.findings.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="10" class="text-center text-muted">
                        <div class="py-4">
                            <i class="fas fa-inbox fa-3x mb-3 text-muted"></i>
                            <h5>No findings found</h5>
                            <p class="text-muted">Try adjusting your filters or run a manual fetch</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.findings.map(finding => `
            <tr class="fade-in-up" data-finding-id="${finding.id}">
                <td>
                    <input type="checkbox" class="form-check-input finding-checkbox" 
                           value="${finding.id}" 
                           ${this.selectedFindings.has(finding.id) ? 'checked' : ''}
                           onchange="dashboard.toggleFindingSelection('${finding.id}')">
                </td>
                <td>
                    <span class="finding-id" title="${finding.id}">${finding.id.substring(0, 8)}...</span>
                </td>
                <td>
                    <div class="finding-title">${this.escapeHtml(finding.title)}</div>
                    ${showDescriptions && finding.description ? `
                        <div class="finding-description mt-2">
                            ${this.escapeHtml(finding.description).substring(0, 150)}${finding.description.length > 150 ? '...' : ''}
                        </div>
                    ` : ''}
                </td>
                <td>
                    <span class="severity-badge severity-${finding.severity?.toLowerCase() || 'unknown'}" 
                          title="Severity: ${finding.severity || 'Unknown'}">
                        ${finding.severity || 'UNKNOWN'}
                    </span>
                </td>
                <td>
                    <span class="status-badge status-${finding.status?.toLowerCase() || 'unknown'}"
                          title="Status: ${finding.status || 'Unknown'}">
                        ${finding.status || 'UNKNOWN'}
                    </span>
                </td>
                <td>
                    <span class="text-truncate d-inline-block" style="max-width: 120px;" 
                          title="${this.escapeHtml(finding.product_name || 'N/A')}">
                        ${this.escapeHtml(finding.product_name || 'N/A')}
                    </span>
                </td>
                <td>
                    <span class="badge bg-secondary">${finding.region || 'N/A'}</span>
                </td>
                <td>
                    <small class="text-muted">
                        ${finding.created_at ? new Date(finding.created_at).toLocaleDateString() : 'N/A'}
                    </small>
                </td>
                <td>
                    <span class="workflow-badge workflow-${finding.workflow_status?.toLowerCase() || 'unknown'}"
                          title="Workflow: ${finding.workflow_status || 'Unknown'}">
                        ${finding.workflow_status || 'UNKNOWN'}
                    </span>
                </td>
                <td>
                    <div class="btn-group btn-group-sm" role="group">
                        <button class="btn btn-outline-primary" onclick="dashboard.viewFinding('${finding.id}')" 
                                title="View Details" data-bs-toggle="tooltip">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-outline-info" onclick="dashboard.viewHistory('${finding.id}')" 
                                title="View History" data-bs-toggle="tooltip">
                            <i class="fas fa-history"></i>
                        </button>
                        <button class="btn btn-outline-warning" onclick="dashboard.addToWatchlist('${finding.id}')" 
                                title="Add to Watchlist" data-bs-toggle="tooltip">
                            <i class="fas fa-eye"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');

        // Initialize tooltips
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    }

    toggleFindingSelection(findingId) {
        if (this.selectedFindings.has(findingId)) {
            this.selectedFindings.delete(findingId);
        } else {
            this.selectedFindings.add(findingId);
        }
        this.updateBulkActions();
    }

    toggleSelectAll(checked) {
        const checkboxes = document.querySelectorAll('.finding-checkbox');
        checkboxes.forEach(checkbox => {
            checkbox.checked = checked;
            if (checked) {
                this.selectedFindings.add(checkbox.value);
            } else {
                this.selectedFindings.delete(checkbox.value);
            }
        });
        this.updateBulkActions();
    }

    updateBulkActions() {
        const bulkExportBtn = document.getElementById('bulk-export-btn');
        const bulkHistoryBtn = document.getElementById('bulk-history-btn');
        const selectedCount = this.selectedFindings.size;
        
        bulkExportBtn.disabled = selectedCount === 0;
        bulkHistoryBtn.disabled = selectedCount === 0;
        
        if (selectedCount > 0) {
            bulkExportBtn.innerHTML = `<i class="fas fa-download me-1"></i> Export (${selectedCount})`;
            bulkHistoryBtn.innerHTML = `<i class="fas fa-history me-1"></i> History (${selectedCount})`;
        } else {
            bulkExportBtn.innerHTML = `<i class="fas fa-download me-1"></i> Bulk Export`;
            bulkHistoryBtn.innerHTML = `<i class="fas fa-history me-1"></i> View History`;
        }
    }

    async viewFinding(findingId) {
        try {
            this.currentFindingId = findingId; // Store the current finding ID
            console.log('Fetching finding with ID:', findingId);
            
            // Use query parameter approach instead of path parameter
            const response = await fetch(`/api/test/finding-by-query?finding_id=${encodeURIComponent(findingId)}`);
            console.log('Response status:', response.status);
            
            if (!response.ok) {
                const errorText = await response.text();
                console.error('API Error:', errorText);
                throw new Error(`API Error: ${response.status} - ${errorText}`);
            }
            
            const result = await response.json();
            
            // Debug: Log the finding data
            console.log('Finding data received:', result);
            
            if (!result.found) {
                throw new Error('Finding not found');
            }
            
            const finding = result.finding;
            
            const modalBody = document.getElementById('finding-modal-body');
            modalBody.innerHTML = `
                <div class="row">
                    <div class="col-md-6">
                        <h6>Basic Information</h6>
                        <table class="table table-sm">
                            <tr><td><strong>ID:</strong></td><td class="finding-id">${finding.id}</td></tr>
                            <tr><td><strong>Title:</strong></td><td>${this.escapeHtml(finding.title)}</td></tr>
                            <tr><td><strong>Severity:</strong></td><td><span class="severity-badge severity-${finding.severity?.toLowerCase() || 'unknown'}">${finding.severity || 'UNKNOWN'}</span></td></tr>
                            <tr><td><strong>Status:</strong></td><td><span class="status-badge status-${finding.status?.toLowerCase() || 'unknown'}">${finding.status || 'UNKNOWN'}</span></td></tr>
                            <tr><td><strong>Product:</strong></td><td>${this.escapeHtml(finding.product_name || 'N/A')}</td></tr>
                            <tr><td><strong>Region:</strong></td><td>${finding.region || 'N/A'}</td></tr>
                        </table>
                    </div>
                    <div class="col-md-6">
                        <h6>Additional Details</h6>
                        <table class="table table-sm">
                            <tr><td><strong>AWS Account:</strong></td><td>${finding.aws_account_id || 'N/A'}</td></tr>
                            <tr><td><strong>Workflow Status:</strong></td><td>${finding.workflow_status || 'N/A'}</td></tr>
                            <tr><td><strong>Compliance Status:</strong></td><td>${finding.compliance_status || 'N/A'}</td></tr>
                            <tr><td><strong>Verification State:</strong></td><td>${finding.verification_state || 'N/A'}</td></tr>
                            <tr><td><strong>Created:</strong></td><td>${finding.created_at ? new Date(finding.created_at).toLocaleString() : 'N/A'}</td></tr>
                            <tr><td><strong>Updated:</strong></td><td>${finding.updated_at ? new Date(finding.updated_at).toLocaleString() : 'N/A'}</td></tr>
                        </table>
                    </div>
                </div>
                <div class="row mt-3">
                    <div class="col-12">
                        <h6>Description</h6>
                        <p class="finding-description">${this.escapeHtml(finding.description || 'No description available')}</p>
                    </div>
                </div>
            `;
            
            const modal = new bootstrap.Modal(document.getElementById('findingModal'));
            modal.show();
        } catch (error) {
            console.error('Error loading finding details:', error);
            this.showError('Failed to load finding details');
        }
    }

    async viewHistory(findingId) {
        try {
            const response = await fetch(`/api/findings/${findingId}/history`);
            const history = await response.json();
            
            const modalBody = document.getElementById('history-modal-body');
            
            if (history.length === 0) {
                modalBody.innerHTML = `
                    <div class="text-center text-muted">
                        <i class="fas fa-history fa-3x mb-3"></i>
                        <p>No history available for this finding</p>
                    </div>
                `;
            } else {
                modalBody.innerHTML = `
                    <div class="history-timeline">
                        ${history.map(item => `
                            <div class="history-item">
                                <div class="history-timestamp">
                                    ${new Date(item.timestamp).toLocaleString()}
                                </div>
                                <div class="history-changes">
                                    ${this.renderChanges(item.changes)}
                                </div>
                            </div>
                        `).join('')}
                    </div>
                `;
            }
            
            const modal = new bootstrap.Modal(document.getElementById('historyModal'));
            modal.show();
        } catch (error) {
            console.error('Error loading finding history:', error);
            this.showError('Failed to load finding history');
        }
    }

    renderChanges(changesStr) {
        if (!changesStr) return '<p>No changes recorded</p>';
        
        try {
            const changes = JSON.parse(changesStr);
            if (changes.action === 'created') {
                return '<p><strong>Finding created</strong></p>';
            }
            
            return Object.entries(changes).map(([key, value]) => `
                <div class="change-item">
                    <span class="change-label">${key.replace(/_/g, ' ').toUpperCase()}:</span>
                    <div class="change-value">
                        <span class="change-old">${value.old || 'N/A'}</span>
                        <i class="fas fa-arrow-right mx-2"></i>
                        <span class="change-new">${value.new || 'N/A'}</span>
                    </div>
                </div>
            `).join('');
        } catch (error) {
            return '<p>Error parsing changes</p>';
        }
    }

    async updateSchedulerStatus() {
        try {
            const response = await fetch('/api/scheduler/status');
            const status = await response.json();
            
            const statusElement = document.getElementById('scheduler-status');
            const icon = statusElement.querySelector('i');
            
            if (status.running) {
                icon.className = 'fas fa-circle text-success';
                statusElement.innerHTML = `<i class="fas fa-circle text-success"></i> Scheduler: Running (Next: ${status.next_run ? new Date(status.next_run).toLocaleTimeString() : 'N/A'})`;
            } else {
                icon.className = 'fas fa-circle text-danger';
                statusElement.innerHTML = `<i class="fas fa-circle text-danger"></i> Scheduler: Stopped`;
            }
        } catch (error) {
            console.error('Error updating scheduler status:', error);
        }
    }

    async manualFetch() {
        try {
            const button = event.target;
            const originalText = button.innerHTML;
            button.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i> Fetching...';
            button.disabled = true;
            
            const response = await fetch('/api/findings/fetch', { method: 'POST' });
            const result = await response.json();
            
            if (response.ok) {
                this.showSuccess('Manual fetch completed successfully');
                await this.loadFindings();
                await this.loadStats();
            } else {
                this.showError('Manual fetch failed');
            }
        } catch (error) {
            console.error('Error during manual fetch:', error);
            this.showError('Manual fetch failed');
        } finally {
            const button = event.target;
            button.innerHTML = originalText;
            button.disabled = false;
        }
    }

    async exportCSV() {
        try {
            const params = this.buildFilterParams();
            window.open(`/api/findings/export/csv?${params}`, '_blank');
        } catch (error) {
            console.error('Error exporting CSV:', error);
            this.showError('Export failed');
        }
    }

    async exportJSON() {
        try {
            const params = this.buildFilterParams();
            const response = await fetch(`/api/findings/export/json?${params}`);
            const data = await response.json();
            
            const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `security_hub_findings_${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        } catch (error) {
            console.error('Error exporting JSON:', error);
            this.showError('Export failed');
        }
    }

    buildFilterParams() {
        const params = new URLSearchParams();
        
        const severity = document.getElementById('severity-filter').value;
        const status = document.getElementById('status-filter').value;
        const product = document.getElementById('product-filter').value;
        const startDate = document.getElementById('start-date').value;
        const endDate = document.getElementById('end-date').value;

        if (severity) params.append('severity', severity);
        if (status) params.append('status', status);
        if (product) params.append('product_name', product);
        if (startDate) params.append('start_date', startDate);
        if (endDate) params.append('end_date', endDate);

        return params;
    }

    applyFilters() {
        this.currentPage = 0;
        this.loadFindings();
    }

    refreshData() {
        this.loadFindings();
        this.loadStats();
    }

    previousPage() {
        if (this.currentPage > 0) {
            this.currentPage--;
            this.loadFindings();
        }
    }

    nextPage() {
        if ((this.currentPage + 1) * this.pageSize < this.totalFindings) {
            this.currentPage++;
            this.loadFindings();
        }
    }

    updatePagination() {
        const prevBtn = document.getElementById('prev-btn');
        const nextBtn = document.getElementById('next-btn');
        const info = document.getElementById('pagination-info');
        
        prevBtn.disabled = this.currentPage === 0;
        nextBtn.disabled = this.findings.length < this.pageSize;
        
        const start = this.currentPage * this.pageSize + 1;
        const end = start + this.findings.length - 1;
        info.textContent = `Showing ${start}-${end} of ${this.totalFindings} findings`;
    }

    showLoading() {
        const tbody = document.getElementById('findings-tbody');
        tbody.innerHTML = `
            <tr>
                <td colspan="8" class="text-center">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </td>
            </tr>
        `;
    }

    showError(message) {
        // Create a simple toast notification
        const toast = document.createElement('div');
        toast.className = 'alert alert-danger alert-dismissible fade show position-fixed';
        toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
        toast.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }

    showSuccess(message) {
        const toast = document.createElement('div');
        toast.className = 'alert alert-success alert-dismissible fade show position-fixed notification-toast';
        toast.innerHTML = `
            <div class="d-flex align-items-center">
                <i class="fas fa-check-circle me-2"></i>
                <span>${message}</span>
                <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
            </div>
        `;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 3000);
    }

    showInfo(message) {
        const toast = document.createElement('div');
        toast.className = 'alert alert-info alert-dismissible fade show position-fixed notification-toast';
        toast.innerHTML = `
            <div class="d-flex align-items-center">
                <i class="fas fa-info-circle me-2"></i>
                <span>${message}</span>
                <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
            </div>
        `;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 4000);
    }

    showWarning(message) {
        const toast = document.createElement('div');
        toast.className = 'alert alert-warning alert-dismissible fade show position-fixed notification-toast';
        toast.innerHTML = `
            <div class="d-flex align-items-center">
                <i class="fas fa-exclamation-triangle me-2"></i>
                <span>${message}</span>
                <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
            </div>
        `;
        document.body.appendChild(toast);
        
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Global functions for onclick handlers
let dashboard;

document.addEventListener('DOMContentLoaded', () => {
    dashboard = new SecurityHubDashboard();
});

function applyFilters() {
    dashboard.applyFilters();
}

function manualFetch() {
    dashboard.manualFetch();
}

function exportCSV() {
    dashboard.exportCSV();
}

function exportJSON() {
    dashboard.exportJSON();
}

function refreshData() {
    dashboard.refreshData();
}

function previousPage() {
    dashboard.previousPage();
}

function nextPage() {
    dashboard.nextPage();
}

// Additional enhanced functions
function clearFilters() {
    document.getElementById('severity-filter').value = '';
    document.getElementById('status-filter').value = '';
    document.getElementById('product-filter').value = '';
    document.getElementById('workflow-filter').value = '';
    document.getElementById('region-filter').value = '';
    document.getElementById('account-filter').value = '';
    document.getElementById('compliance-filter').value = '';
    document.getElementById('start-date').value = '';
    document.getElementById('end-date').value = '';
    
    // Clear active filter tags
    document.getElementById('active-filters').innerHTML = '';
    
    // Apply cleared filters
    dashboard.applyFilters();
}

function saveFilterPreset() {
    const modal = new bootstrap.Modal(document.getElementById('presetModal'));
    modal.show();
}

function savePreset() {
    const name = document.getElementById('preset-name').value;
    const description = document.getElementById('preset-description').value;
    
    if (!name.trim()) {
        dashboard.showError('Please enter a preset name');
        return;
    }
    
    const filters = {
        severity: document.getElementById('severity-filter').value,
        status: document.getElementById('status-filter').value,
        product: document.getElementById('product-filter').value,
        workflow: document.getElementById('workflow-filter').value,
        region: document.getElementById('region-filter').value,
        account: document.getElementById('account-filter').value,
        compliance: document.getElementById('compliance-filter').value,
        startDate: document.getElementById('start-date').value,
        endDate: document.getElementById('end-date').value
    };
    
    const preset = {
        id: Date.now(),
        name: name,
        description: description,
        filters: filters,
        createdAt: new Date().toISOString()
    };
    
    dashboard.filterPresets.push(preset);
    dashboard.saveFilterPresets();
    
    const modal = bootstrap.Modal.getInstance(document.getElementById('presetModal'));
    modal.hide();
    
    dashboard.showSuccess('Filter preset saved successfully');
}

function openSettings() {
    const modal = new bootstrap.Modal(document.getElementById('settingsModal'));
    
    // Load current settings
    document.getElementById('refresh-interval').value = dashboard.settings.autoRefreshInterval || 60;
    document.getElementById('default-page-size').value = dashboard.settings.defaultPageSize || 50;
    document.getElementById('show-descriptions-default').checked = dashboard.settings.showDescriptionsDefault || false;
    document.getElementById('enable-notifications').checked = dashboard.settings.enableNotifications || false;
    
    modal.show();
}

function saveSettings() {
    dashboard.settings.autoRefreshInterval = parseInt(document.getElementById('refresh-interval').value);
    dashboard.settings.defaultPageSize = parseInt(document.getElementById('default-page-size').value);
    dashboard.settings.showDescriptionsDefault = document.getElementById('show-descriptions-default').checked;
    dashboard.settings.enableNotifications = document.getElementById('enable-notifications').checked;
    
    dashboard.saveSettings();
    dashboard.setupAutoRefresh();
    
    const modal = bootstrap.Modal.getInstance(document.getElementById('settingsModal'));
    modal.hide();
    
    dashboard.showSuccess('Settings saved successfully');
}

function bulkExport() {
    if (dashboard.selectedFindings.size === 0) {
        dashboard.showError('Please select findings to export');
        return;
    }
    
    const modal = new bootstrap.Modal(document.getElementById('bulkModal'));
    document.getElementById('selected-count').textContent = dashboard.selectedFindings.size;
    modal.show();
}

function bulkHistory() {
    if (dashboard.selectedFindings.size === 0) {
        dashboard.showError('Please select findings to view history');
        return;
    }
    
    const modal = new bootstrap.Modal(document.getElementById('bulkModal'));
    document.getElementById('selected-count').textContent = dashboard.selectedFindings.size;
    modal.show();
}

function bulkExportSelected() {
    const findingIds = Array.from(dashboard.selectedFindings);
    const params = new URLSearchParams();
    params.append('finding_ids', findingIds.join(','));
    
    window.open(`/api/findings/export/csv?${params}`, '_blank');
    
    const modal = bootstrap.Modal.getInstance(document.getElementById('bulkModal'));
    modal.hide();
}

function bulkHistorySelected() {
    // This would need backend support for bulk history
    dashboard.showInfo('Bulk history feature coming soon');
    
    const modal = bootstrap.Modal.getInstance(document.getElementById('bulkModal'));
    modal.hide();
}

function bulkAddToWatchlist() {
    const findingIds = Array.from(dashboard.selectedFindings);
    findingIds.forEach(id => dashboard.addToWatchlist(id));
    
    const modal = bootstrap.Modal.getInstance(document.getElementById('bulkModal'));
    modal.hide();
    
    dashboard.showSuccess(`Added ${findingIds.length} findings to watchlist`);
}

function addToWatchlist(findingId) {
    try {
        let watchlist = JSON.parse(localStorage.getItem('securityHubWatchlist') || '[]');
        if (!watchlist.includes(findingId)) {
            watchlist.push(findingId);
            localStorage.setItem('securityHubWatchlist', JSON.stringify(watchlist));
            dashboard.showSuccess('Added to watchlist');
        } else {
            dashboard.showInfo('Already in watchlist');
        }
    } catch (error) {
        dashboard.showError('Failed to add to watchlist');
    }
}

function viewHistoryFromDetails() {
    const modal = bootstrap.Modal.getInstance(document.getElementById('findingModal'));
    modal.hide();
    
    // Get the current finding ID from the modal
    const findingId = dashboard.currentFindingId;
    if (findingId) {
        dashboard.viewHistory(findingId);
    }
}

function exportFinding() {
    const findingId = dashboard.currentFindingId;
    if (findingId) {
        window.open(`/api/findings/export/csv?finding_ids=${findingId}`, '_blank');
    }
}

// Enhanced notification system
function showNotification(title, message, type = 'info') {
    if (!dashboard.settings.enableNotifications) return;
    
    if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(title, {
            body: message,
            icon: '/static/favicon.ico',
            tag: 'security-hub'
        });
    }
}

// Request notification permission
if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
}

// Comment management functions
let currentFindingId = null;

function viewComments() {
    const findingId = dashboard.currentFindingId;
    if (!findingId) {
        dashboard.showError('No finding selected');
        return;
    }
    
    currentFindingId = findingId;
    loadComments(findingId);
    
    const modal = new bootstrap.Modal(document.getElementById('commentsModal'));
    modal.show();
}

async function loadComments(findingId) {
    try {
        // Use query parameter approach instead of path parameter
        const response = await fetch(`/api/test/comments-by-query?finding_id=${encodeURIComponent(findingId)}`);
        if (!response.ok) {
            throw new Error('Failed to load comments');
        }
        
        const result = await response.json();
        renderComments(result.comments || []);
    } catch (error) {
        console.error('Error loading comments:', error);
        dashboard.showError('Failed to load comments');
    }
}

function renderComments(comments) {
    const commentsList = document.getElementById('comments-list');
    
    if (comments.length === 0) {
        commentsList.innerHTML = '<p class="text-muted text-center">No comments yet. Be the first to add one!</p>';
        return;
    }
    
    commentsList.innerHTML = comments.map(comment => `
        <div class="card mb-3 ${comment.is_internal ? 'border-warning' : 'border-primary'}">
            <div class="card-header d-flex justify-content-between align-items-center">
                <div>
                    <strong>${escapeHtml(comment.author)}</strong>
                    ${comment.is_internal ? '<span class="badge bg-warning ms-2">Internal</span>' : ''}
                </div>
                <small class="text-muted">${new Date(comment.created_at).toLocaleString()}</small>
            </div>
            <div class="card-body">
                <p class="card-text">${escapeHtml(comment.comment)}</p>
                <div class="d-flex justify-content-end gap-2">
                    <button class="btn btn-sm btn-outline-primary" onclick="editComment(${comment.id})">
                        <i class="fas fa-edit"></i> Edit
                    </button>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteComment(${comment.id})">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

async function addComment() {
    const commentText = document.getElementById('new-comment').value.trim();
    const isInternal = document.getElementById('internal-comment').checked;
    
    if (!commentText) {
        dashboard.showError('Please enter a comment');
        return;
    }
    
    if (!dashboard.currentFindingId) {
        dashboard.showError('No finding selected');
        return;
    }
    
    try {
        const response = await fetch(`/api/findings/${dashboard.currentFindingId}/comments`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                comment: commentText,
                author: 'User', // You could get this from user session
                is_internal: isInternal
            })
        });
        
        if (!response.ok) {
            throw new Error('Failed to add comment');
        }
        
        const newComment = await response.json();
        dashboard.showSuccess('Comment added successfully');
        
        // Clear the form
        document.getElementById('new-comment').value = '';
        document.getElementById('internal-comment').checked = false;
        
        // Reload comments
        await loadComments(dashboard.currentFindingId);
        
    } catch (error) {
        console.error('Error adding comment:', error);
        dashboard.showError('Failed to add comment');
    }
}

async function editComment(commentId) {
    const newComment = prompt('Edit your comment:');
    if (!newComment || !newComment.trim()) return;
    
    try {
        const response = await fetch(`/api/findings/${dashboard.currentFindingId}/comments/${commentId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                comment: newComment.trim(),
                author: 'User',
                is_internal: false
            })
        });
        
        if (!response.ok) {
            throw new Error('Failed to update comment');
        }
        
        dashboard.showSuccess('Comment updated successfully');
        await loadComments(dashboard.currentFindingId);
        
    } catch (error) {
        console.error('Error updating comment:', error);
        dashboard.showError('Failed to update comment');
    }
}

async function deleteComment(commentId) {
    if (!confirm('Are you sure you want to delete this comment?')) return;
    
    try {
        const response = await fetch(`/api/findings/${dashboard.currentFindingId}/comments/${commentId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error('Failed to delete comment');
        }
        
        dashboard.showSuccess('Comment deleted successfully');
        await loadComments(dashboard.currentFindingId);
        
    } catch (error) {
        console.error('Error deleting comment:', error);
        dashboard.showError('Failed to delete comment');
    }
} 