<!DOCTYPE html>
<html lang="en">
<head>
    <?php session_start(); ?>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>e-Report - Community Issue Reporting + Analytics Dashboard</title>
    <link rel="stylesheet" href="css/bootstrap.min.css">
    <link defer rel="stylesheet" href="js/bootstrap.bundle.min.js">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
    <!-- Leaflet CSS + JS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <!-- Chart.js CDN for bar graph -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Archivo+Black&family=Bebas+Neue&family=DM+Serif+Display:ital@0;1&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;1,9..40,300&family=Lobster+Two:ital,wght@0,400;0,700;1,400;1,700&family=Roboto+Slab:wght@100..900&family=Tapestry&display=swap');

    /* ── Scroll offset: every anchor lands 70px (navbar) + 12px gap below navbar ── */
    :root { --navbar-height: 70px; --scroll-gap: 12px; }
    html { scroll-behavior: smooth; }

    body { background-image: linear-gradient(45deg, #8baaaa 0%, #ae8b9c 100%); min-height: 100vh; }
    .navbar-brand { font-weight: light; }
    .card { border-radius: 15px; transition: all 0.2s ease; border: none; }
    .btn-primary { background-color: #000; border: none; }

    .user-avatar {
        width: 40px; height: 40px;
        border-radius: 50%;
        background-color: #000; color: white;
        display: flex; align-items: center; justify-content: center;
        font-weight: bold; font-size: 14px; text-transform: uppercase;
    }
    .navbar-nav .nav-link { cursor: pointer; }

    /* ── Brand two-line serif (matches user page) ── */
    .nav-brand-text {
        font-family: 'DM Serif Display', Georgia, serif;
        font-size: 1.15rem;
        line-height: 1.2;
        color: #0e0e0e;
    }
    .nav-brand-text small {
        display: block;
        font-family: 'DM Sans', system-ui, sans-serif;
        font-size: 0.62rem;
        font-weight: 600;
        letter-spacing: .13em;
        text-transform: uppercase;
        color: #555;
        margin-bottom: 1px;
    }

    /* ── Map ── */
    #municipalityMap {
        height: 420px; width: 100%;
        border-radius: 15px; z-index: 1;
        box-shadow: 0 4px 20px rgba(0,0,0,0.15);
    }

    /* ── Analytics row ── */
    .analytics-row {
        display: flex;
        gap: 1.25rem;
        align-items: stretch;
        margin-bottom: 1.25rem;
    }
    .panel-bar-graph {
        flex: 0 0 60%;
        background: white;
        border-radius: 16px;
        padding: 1.25rem 1.5rem;
        box-shadow: 0 4px 16px rgba(0,0,0,0.08);
        display: flex;
        flex-direction: column;
    }
    .panel-bar-graph canvas { flex: 1; min-height: 0; width: 100% !important; }
    .panel-status-summary {
        flex: 1;
        background: white;
        border-radius: 16px;
        padding: 1.25rem 1.5rem;
        box-shadow: 0 4px 16px rgba(0,0,0,0.08);
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    /* KPI cards */
    .kpi-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; }
    .stat-card {
        background: #f8f9fa; border-radius: 12px; padding: 0.8rem 0.7rem;
        text-align: center; transition: transform 0.2s;
        display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 0.15rem;
    }
    .stat-card:hover { transform: translateY(-2px); }
    .stat-icon { font-size: 1.3rem; opacity: 0.7; line-height: 1; }
    .stat-value { font-size: clamp(1.1rem, 2.2vw, 1.6rem); font-weight: 800; color: #2c3e50; line-height: 1.1; word-break: break-word; }
    .stat-label { font-size: 0.68rem; color: #6c757d; text-transform: uppercase; letter-spacing: 0.8px; }

    /* Status badges */
    .status-badges { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.5rem; }
    .status-badge-item {
        border-radius: 10px; padding: 0.6rem 0.4rem;
        text-align: center; font-size: 0.72rem; font-weight: 600; color: white;
        display: flex; flex-direction: column; gap: 0.2rem;
    }
    .status-badge-item .badge-count { font-size: 1.2rem; font-weight: 800; line-height: 1; }

    /* Top categories */
    .top-category-item {
        background: #f8f9fa; border-radius: 10px; padding: 8px 12px; margin-bottom: 6px;
        display: flex; justify-content: space-between; align-items: center; font-size: 0.85rem;
    }
    .legend-status { display: inline-block; width: 12px; height: 12px; border-radius: 3px; margin-right: 5px; }

    /* Report cards */
    .report-photo-wrapper { position: relative; cursor: pointer; overflow: hidden; border-radius: 15px 15px 0 0; }
    .report-photo-wrapper img, .report-photo-wrapper .no-photo {
        width: 100%; height: 200px; object-fit: cover; display: block;
        transition: filter 0.25s ease, transform 0.25s ease;
    }
    .report-photo-wrapper .no-photo { background: #6c757d; display: flex; align-items: center; justify-content: center; }
    .report-photo-wrapper .photo-overlay {
        position: absolute; inset: 0; background: rgba(0,0,0,0);
        display: flex; align-items: center; justify-content: center; transition: background 0.25s ease;
    }
    .report-photo-wrapper .photo-overlay span {
        color: #fff; font-size: 0.8rem; font-weight: 600;
        background: rgba(0,0,0,0.55); padding: 4px 10px; border-radius: 20px;
        opacity: 0; transform: translateY(6px); transition: opacity 0.25s ease, transform 0.25s ease; pointer-events: none;
    }
    .report-photo-wrapper:hover img, .report-photo-wrapper:hover .no-photo { filter: brightness(0.75); transform: scale(1.03); }
    .report-photo-wrapper:hover .photo-overlay { background: rgba(0,0,0,0.15); }
    .report-photo-wrapper:hover .photo-overlay span { opacity: 1; transform: translateY(0); }
    .report-photo-wrapper.no-gps { cursor: default; }
    .report-photo-wrapper.no-gps:hover img, .report-photo-wrapper.no-gps:hover .no-photo { filter: none; transform: none; }
    .report-photo-wrapper.no-gps:hover .photo-overlay span { opacity: 0; }

    .pin-active { border: 3px solid #ff9800; box-shadow: 0 0 15px rgba(255,152,0,0.5); transition: all 0.2s; }

    /* Responsive */
    @media (max-width: 768px) {
        .analytics-row { flex-direction: column; }
        .panel-bar-graph { flex: none; }
        .status-badges { grid-template-columns: repeat(2, 1fr); }
    }
    </style>
</head>
<body>

<!-- Fixed Navbar -->
<nav class="navbar navbar-expand-lg shadow-sm fixed-top" id="mainNavbar"
     style="padding: 0.35rem 1rem; background-image: linear-gradient(45deg, #8baaaa 0%, #ae8b9c 100%);">
    <div class="container-fluid px-2 px-lg-3">
        <a class="navbar-brand d-flex align-items-center gap-2" href="#">
            <img src="./image/lgu.png" alt="Logo" width="40" height="40" class="d-inline-block" style="border-radius:8px; object-fit:contain;">
            <div class="nav-brand-text">
                <small>Municipality of</small>
                Lambunao
            </div>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarMain">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarMain">
            <ul class="navbar-nav ms-auto mb-2 mb-lg-0 align-items-center gap-2">
                <?php if (isset($_SESSION['firstname']) && isset($_SESSION['lastname'])): ?>
                    <li class="nav-item"><a class="btn btn-sm btn-outline-dark" href="#" onclick="navScrollTo('analytics-section'); return false;"><i class="bi bi-bar-chart"></i> Dashboard</a></li>
                    <li class="nav-item"><a class="btn btn-sm btn-outline-dark" href="#" onclick="navScrollTo('municipalityMap'); return false;"><i class="bi bi-map"></i> Map</a></li>
                    <li class="nav-item"><a class="btn btn-sm btn-outline-dark" href="#" onclick="navScrollTo('allreports'); return false;"><i class="bi bi-list-check"></i> All Reports</a></li>
                    <li class="nav-item"><a href="index.php?logout=true" class="btn btn-sm btn-danger"><i class="bi bi-box-arrow-right"></i> Logout</a></li>
                    <li class="nav-item">
                        <div class="user-avatar" title="<?php echo htmlspecialchars($_SESSION['firstname'] . ' ' . $_SESSION['lastname']); ?>">
                            <?php
                                $firstInitial = !empty($_SESSION['firstname']) ? substr($_SESSION['firstname'], 0, 1) : '';
                                $lastInitial  = !empty($_SESSION['lastname'])  ? substr($_SESSION['lastname'],  0, 1) : '';
                                echo htmlspecialchars($firstInitial . $lastInitial);
                            ?>
                        </div>
                    </li>
                <?php else: ?>
                    <li class="nav-item"><a href="index.php" class="btn btn-sm btn-dark">Login</a></li>
                <?php endif; ?>
            </ul>
        </div>
    </div>
</nav>

<div class="container-fluid px-3 px-lg-4" style="padding-top: 82px; max-width: 1400px; margin: 0 auto;">

    <!-- SECTION 1: Map -->
    <div class="mb-4" id="map-section">
        <div id="municipalityMap"></div>
    </div>

    <!-- SECTION 2: Bar Graph (60%) + Status Summary (40%) -->
    <div class="analytics-row" id="analytics-section">
        <!-- Bar Graph -->
        <div class="panel-bar-graph">
            <div class="d-flex justify-content-between align-items-center flex-wrap mb-3">
                <h5 style="font-family: 'Roboto Slab', serif; margin: 0;">
                    <i class="bi bi-bar-chart-steps me-2"></i>Monthly Issue Records
                </h5>
                <div class="d-flex gap-3 flex-wrap" style="font-size:0.78rem;">
                    <div><span class="legend-status" style="background:#ffc107;"></span>Pending</div>
                    <div><span class="legend-status" style="background:#0dcaf0;"></span>In-Progress</div>
                    <div><span class="legend-status" style="background:#dc3545;"></span>Rejected</div>
                    <div><span class="legend-status" style="background:#198754;"></span>Resolved</div>
                </div>
            </div>
            <canvas id="monthlyStatusChart"></canvas>
            <div class="mt-2 text-muted" style="font-size:0.73rem; text-align:center;">
                <i class="bi bi-info-circle"></i> Reports per month (Jan–Dec), grouped by status
            </div>
        </div>

        <!-- Status Summary -->
        <div class="panel-status-summary">
            <h5 style="font-family: 'Roboto Slab', serif; margin: 0 0 0.5rem 0;">
                <i class="bi bi-speedometer2 me-2"></i>Status Summary
            </h5>
            <div class="kpi-grid">
                <div class="stat-card">
                    <div class="stat-icon"><i class="bi bi-files"></i></div>
                    <div class="stat-value" id="totalReportsCount">0</div>
                    <div class="stat-label">Total Reports</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon"><i class="bi bi-trophy-fill text-warning"></i></div>
                    <div class="stat-value" id="topCategoryLabel">—</div>
                    <div class="stat-label">Top Category</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon"><i class="bi bi-calendar-month text-info"></i></div>
                    <div class="stat-value" id="busiestMonthLabel">—</div>
                    <div class="stat-label">Highest Reports Month</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon"><i class="bi bi-check-circle-fill text-success"></i></div>
                    <div class="stat-value" id="totalResolvedCount">0</div>
                    <div class="stat-label">Resolved Reports</div>
                </div>
            </div>
            <div>
                <div class="status-badges">
                    <div class="status-badge-item" style="background:#ffc107;">
                        <span class="badge-count" id="pendingCount">0</span><span>Pending</span>
                    </div>
                    <div class="status-badge-item" style="background:#0dcaf0;">
                        <span class="badge-count" id="inprogressCount">0</span><span>In-Progress</span>
                    </div>
                    <div class="status-badge-item" style="background:#dc3545;">
                        <span class="badge-count" id="rejectedCount">0</span><span>Rejected</span>
                    </div>
                    <div class="status-badge-item" style="background:#198754;">
                        <span class="badge-count" id="resolvedCount">0</span><span>Resolved</span>
                    </div>
                </div>
            </div>
            <div class="flex-grow-1" style="overflow-y: auto; min-height: 0;">
                <h6 class="mb-2"><i class="bi bi-tag me-1"></i>Top Report Categories</h6>
                <div id="categoryList"><div class="text-muted small">Loading...</div></div>
            </div>
        </div>
    </div>

    <!-- SECTION 3: All Reports -->
    <div class="card shadow p-4 mb-4" id="allreports">
        <h4 class="mb-3" style="font-family: 'Roboto Slab', serif;">
            <i class="bi bi-file-earmark-text me-2"></i>All Community Reports
        </h4>
        <div id="allReports" class="row g-3"></div>
    </div>

</div>

<script src="js/jquery.js"></script>
<script>
    let latestReportId = 0;
    let reportStatusSnapshot = {};
    let map, markersLayer;
    const markerMap = {};
    let chartInstance = null;
    let allReportsCache = [];

    const FULL_MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    /* ─────────────────────────────────────────────
       Navbar-aware smooth scroll
       Reads the actual navbar height at call-time
       so it works regardless of screen / collapse state.
    ───────────────────────────────────────────── */
    function navScrollTo(id) {
        const el = document.getElementById(id);
        if (!el) return;
        const navbar  = document.getElementById('mainNavbar');
        const navH    = navbar ? navbar.offsetHeight : 70;
        const gap     = 12; // px gap below navbar
        const top     = el.getBoundingClientRect().top + window.scrollY - navH - gap;
        window.scrollTo({ top, behavior: 'smooth' });
    }

    function initMap() {
        map = L.map('municipalityMap').setView([11.0506, 122.4764], 11);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);
        markersLayer = L.layerGroup().addTo(map);
    }

    function computeFullYearMonthlyStats(reports) {
        const monthlyData = {};
        FULL_MONTHS.forEach(m => { monthlyData[m] = { pending:0, inprogress:0, rejected:0, resolved:0 }; });
        reports.forEach(r => {
            if (!r.timestamp) return;
            const d = new Date(r.timestamp);
            if (isNaN(d)) return;
            const m = FULL_MONTHS[d.getMonth()];
            const s = normalizeStatus(r.status);
            if (s === 'pending')      monthlyData[m].pending++;
            else if (s === 'in-progress') monthlyData[m].inprogress++;
            else if (s === 'rejected')    monthlyData[m].rejected++;
            else if (s === 'resolved')    monthlyData[m].resolved++;
            else monthlyData[m].pending++;
        });
        return {
            months: FULL_MONTHS,
            pendingData:    FULL_MONTHS.map(m => monthlyData[m].pending),
            inprogressData: FULL_MONTHS.map(m => monthlyData[m].inprogress),
            rejectedData:   FULL_MONTHS.map(m => monthlyData[m].rejected),
            resolvedData:   FULL_MONTHS.map(m => monthlyData[m].resolved)
        };
    }

    function updateAnalyticsDashboard(reports) {
        const total      = reports.length;
        const resolved   = reports.filter(r => normalizeStatus(r.status) === 'resolved').length;
        const pending    = reports.filter(r => normalizeStatus(r.status) === 'pending').length;
        const inprogress = reports.filter(r => normalizeStatus(r.status) === 'in-progress').length;
        const rejected   = reports.filter(r => normalizeStatus(r.status) === 'rejected').length;

        document.getElementById('totalReportsCount').innerText  = total;
        document.getElementById('totalResolvedCount').innerText = resolved;
        document.getElementById('pendingCount').innerText       = pending;
        document.getElementById('inprogressCount').innerText    = inprogress;
        document.getElementById('rejectedCount').innerText      = rejected;
        document.getElementById('resolvedCount').innerText      = resolved;

        const catMap = new Map();
        reports.forEach(r => { if (r.category) catMap.set(r.category, (catMap.get(r.category)||0)+1); });
        let topCat = 'None', topCnt = 0;
        for (let [c, n] of catMap) { if (n > topCnt) { topCnt = n; topCat = c; } }
        document.getElementById('topCategoryLabel').innerHTML =
            topCat !== 'None' ? `${topCat}<small style="font-size:0.65rem;"> (${topCnt})</small>` : '—';

        const mCounts = new Array(12).fill(0);
        reports.forEach(r => { if (r.timestamp) { const d = new Date(r.timestamp); if (!isNaN(d)) mCounts[d.getMonth()]++; } });
        let maxC = 0, maxI = -1;
        mCounts.forEach((c,i) => { if (c > maxC) { maxC = c; maxI = i; } });
        document.getElementById('busiestMonthLabel').innerHTML =
            (maxI >= 0 && maxC > 0) ? `${FULL_MONTHS[maxI]} <small style="font-size:0.65rem;">(${maxC})</small>` : '—';

        const sorted = Array.from(catMap.entries()).sort((a,b) => b[1]-a[1]).slice(0,5);
        document.getElementById('categoryList').innerHTML = sorted.length === 0
            ? '<div class="text-muted small">No categories yet</div>'
            : sorted.map(([cat, cnt]) => `
                <div class="top-category-item">
                    <span><i class="bi bi-tag"></i> ${escapeHtml(cat)}</span>
                    <span class="badge bg-secondary rounded-pill">${cnt}</span>
                </div>`).join('');
    }

    function updateBarChartFullYear(reports) {
        const { months, pendingData, inprogressData, rejectedData, resolvedData } = computeFullYearMonthlyStats(reports);
        const ctx = document.getElementById('monthlyStatusChart').getContext('2d');
        if (chartInstance) chartInstance.destroy();
        chartInstance = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: months,
                datasets: [
                    { label:'Pending',     data:pendingData,     backgroundColor:'#ffc107', borderColor:'#e0a800', borderWidth:1, borderRadius:5, barPercentage:0.7 },
                    { label:'In-Progress', data:inprogressData,  backgroundColor:'#0dcaf0', borderColor:'#0aa2c0', borderRadius:5 },
                    { label:'Rejected',    data:rejectedData,    backgroundColor:'#dc3545', borderColor:'#b02a37', borderRadius:5 },
                    { label:'Resolved',    data:resolvedData,    backgroundColor:'#198754', borderColor:'#0f673f', borderRadius:5 }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    tooltip: { callbacks: { label: ctx => `${ctx.dataset.label}: ${ctx.raw} reports` } },
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true, title: { display:true, text:'Reports' }, ticks: { precision:0 } },
                    x: { title: { display:true, text:'Month' }, ticks: { autoSkip:false, maxRotation:0, font:{ weight:'bold' } } }
                }
            }
        });
    }

    function loadAllReports() {
        $.get("./php/get_all_reports.php", function (data) {
            let dataX;
            try { dataX = JSON.parse(data); } catch(e) { console.error(e); return; }
            if (dataX.status !== "success") return;
            const reports = dataX.reports || [];
            allReportsCache = reports;
            updateAnalyticsDashboard(reports);
            updateBarChartFullYear(reports);
            reports.forEach(r => { reportStatusSnapshot[r.reportID] = normalizeStatus(r.status||'pending'); });
            latestReportId = reports.length ? reports[0].reportID : 0;
            displayAllReports(reports);
        }).fail(err => console.log("Error:", err));
    }

    function displayAllReports(reports) {
        const container = $('#allReports');
        container.empty();
        if (markersLayer) markersLayer.clearLayers();
        Object.keys(markerMap).forEach(k => delete markerMap[k]);
        reportStatusSnapshot = {};

        if (!reports.length) {
            container.html('<div class="col-12"><div class="alert alert-info">No reports submitted yet.</div></div>');
            return;
        }

        reports.forEach(report => {
            const status  = report.status || 'pending';
            const hasGPS  = !!(report.latitude && report.longitude);
            const ts      = report.timestamp ? new Date(report.timestamp).toLocaleString() : 'N/A';
            const name    = (report.firstname && report.lastname) ? `${report.firstname} ${report.lastname}` : 'Unknown';
            reportStatusSnapshot[report.reportID] = status;

            const norm = normalizeStatus(status);
            let sCls = 'bg-warning text-dark';
            if (norm === 'resolved')   sCls = 'bg-success';
            else if (norm === 'rejected')   sCls = 'bg-danger';
            else if (norm === 'in-progress') sCls = 'bg-info';
            const sLabel = status.charAt(0).toUpperCase() + status.slice(1);

            const inProgDis = status === 'pending' ? '' : 'disabled';
            const rejDis    = status === 'pending' ? '' : 'disabled';
            const resDis    = (status === 'rejected' || status === 'resolved') ? 'disabled' : '';

            const photoInner = report.photo
                ? `<img src="${report.photo}" alt="Report Photo">`
                : `<div class="no-photo"><i class="bi bi-image text-white" style="font-size:3rem;"></i></div>`;
            const wCls     = hasGPS ? '' : 'no-gps';
            const oLabel   = hasGPS ? '<i class="bi bi-geo-alt-fill me-1"></i>Show on Map' : '<i class="bi bi-geo-alt me-1"></i>No GPS data';
            const cAttr    = hasGPS ? `onclick="focusReportOnMap(${report.reportID},${report.latitude},${report.longitude})"` : '';
            const coordHtml= hasGPS ? `<p class="card-text small mb-1 text-success"><i class="bi bi-geo-alt-fill me-1"></i>GPS: ${parseFloat(report.latitude).toFixed(5)}, ${parseFloat(report.longitude).toFixed(5)}</p>` : '';

            container.append(`
                <div class="col-md-6 col-lg-4">
                    <div class="card h-100 shadow-sm" data-report-id="${report.reportID}">
                        <div class="report-photo-wrapper ${wCls}" ${cAttr}>
                            ${photoInner}
                            <div class="photo-overlay"><span>${oLabel}</span></div>
                        </div>
                        <div class="card-body d-flex flex-column">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <h6 class="card-title mb-0"><i class="bi bi-folder-fill me-1"></i>${escapeHtml(report.category)}</h6>
                                <p class="card-text small text-muted mb-0"><i class="bi bi-clock me-1"></i>${ts}</p>
                            </div>
                            <p class="card-text small mb-1"><i class="bi bi-text-paragraph me-1"></i>${escapeHtml(report.description)}</p>
                            <p class="card-text small mb-1"><i class="bi bi-geo-alt-fill me-1"></i>${escapeHtml(report.location)}</p>
                            <p class="card-text small mb-1"><i class="bi bi-person-fill me-1"></i>${escapeHtml(name)}</p>
                            ${coordHtml}
                            <div class="mt-auto">
                                <span class="badge ${sCls}">${sLabel}</span>
                                <div class="mt-2 d-flex gap-2">
                                    <button class="btn btn-sm btn-info flex-fill" onclick="updateStatus(${report.reportID},'in-progress')" ${inProgDis}><i class="bi bi-arrow-repeat"></i> In Progress</button>
                                    <button class="btn btn-sm btn-danger flex-fill" onclick="updateStatus(${report.reportID},'rejected')" ${rejDis}><i class="bi bi-x-circle"></i> Rejected</button>
                                    <button class="btn btn-sm btn-success flex-fill" onclick="updateStatus(${report.reportID},'resolved')" ${resDis}><i class="bi bi-check-circle"></i> Resolved</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>`);

            if (hasGPS && markersLayer) {
                const popup = `<div style="min-width:160px;">${report.photo ? `<img src="${report.photo}" style="width:100%;height:80px;object-fit:cover;border-radius:6px;margin-bottom:6px;">` : ''}<strong>${escapeHtml(report.category)}</strong><br><small>${escapeHtml(report.description.substring(0,80))}</small><br><small class="text-muted">${escapeHtml(name)}</small><br><span class="badge ${sCls}">${sLabel}</span></div>`;
                const marker = L.marker([parseFloat(report.latitude), parseFloat(report.longitude)]).bindPopup(popup);
                markersLayer.addLayer(marker);
                markerMap[report.reportID] = marker;
            }
        });
    }

    function focusReportOnMap(reportID, lat, lng) {
        if (!map) return;
        document.querySelectorAll('.card.pin-active').forEach(el => el.classList.remove('pin-active'));
        const card = document.querySelector(`.card[data-report-id="${reportID}"]`);
        if (card) card.classList.add('pin-active');
        navScrollTo('municipalityMap');
        map.flyTo([lat, lng], 16, { animate: true, duration: 1.2 });
        setTimeout(() => { if (markerMap[reportID]) markerMap[reportID].openPopup(); }, 1300);
    }

    function updateStatus(reportId, newStatus) {
        if (!confirm(`Change status to "${newStatus}"?`)) return;
        $.post("./php/update_status.php", { report_id: reportId, status: newStatus }, function (data) {
            let dataX = JSON.parse(data);
            if (dataX.status === "success") { alert("Status updated!"); latestReportId = 0; loadAllReports(); }
            else alert("Error: " + (dataX.message || "Failed"));
        }).fail(() => alert("Request failed"));
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str).replace(/[&<>]/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;'}[m]));
    }

    function normalizeStatus(status) {
        let s = (status || 'pending').trim().toLowerCase().replace(/\s+/g, '-');
        if (s === 'in-progres') s = 'in-progress';
        return s;
    }

    $(document).ready(function () {
        initMap();
        loadAllReports();
        setInterval(loadAllReports, 5000);
    });
</script>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>