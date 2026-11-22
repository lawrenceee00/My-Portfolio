<?php
session_start();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>e-Report · Lambunao</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;1,9..40,300&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" crossorigin="" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" crossorigin=""></script>
    <script src="https://cdn.jsdelivr.net/npm/exif-js@2.3.0/exif.js"></script>

    <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
        --ink:       #0e0e0e;
        --ink-2:     #2e2e2e;
        --ink-3:     #6b6b6b;
        --paper:     #f8f5ef;
        --paper-2:   #ede9e0;
        --paper-3:   #e2ddd3;
        --leaf:      #2d6a4f;
        --sky:       #1d5f8a;
        --sun:       #c17f24;
        --danger:    #c94f2c;
        --radius:    12px;
        --radius-lg: 20px;
        --shadow:    0 2px 12px rgba(0,0,0,.08), 0 1px 3px rgba(0,0,0,.06);
        --shadow-lg: 0 8px 40px rgba(0,0,0,.12), 0 2px 8px rgba(0,0,0,.08);
        --font-head: 'DM Serif Display', Georgia, serif;
        --font-body: 'DM Sans', system-ui, sans-serif;
        --nav-h: 64px;
        --card-gap: 24px;
    }

    html { scroll-behavior: smooth; }

    body {
        font-family: var(--font-body);
        background-image: linear-gradient(45deg, #8baaaa 0%, #ae8b9c 100%);
        color: var(--ink);
        min-height: 100vh;
        overflow: hidden;
    }

    /* ── NAVBAR ── */
    .nav-bar {
        position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
        background: rgba(248, 245, 239, 0.92);
        backdrop-filter: blur(16px) saturate(160%);
        -webkit-backdrop-filter: blur(16px) saturate(160%);
        border-bottom: 1px solid var(--paper-3);
        height: var(--nav-h);
        display: flex; align-items: center;
        padding: 0 20px;
        gap: 12px;
    }
    .nav-brand {
        display: flex; align-items: center; gap: 10px;
        text-decoration: none; color: var(--ink); flex: 1;
        min-width: 0;
    }
    .nav-brand img { width: 36px; height: 36px; border-radius: 8px; object-fit: contain; flex-shrink: 0; }
    .nav-brand-text { font-family: var(--font-head); font-size: 1.05rem; line-height: 1.2; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .nav-brand-text small { display: block; font-family: var(--font-body); font-size: 0.62rem; font-weight: 500; letter-spacing: .12em; text-transform: uppercase; color: var(--accent); }
    .nav-user { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
    .nav-welcome { font-size: 0.82rem; font-weight: 500; color: var(--ink-2); white-space: nowrap; }
    @media (max-width: 560px) { .nav-welcome { display: none; } }
    .avatar {
        width: 34px; height: 34px; border-radius: 50%;
        background: var(--ink); color: #fff;
        display: flex; align-items: center; justify-content: center;
        font-size: 0.72rem; font-weight: 600; letter-spacing: .02em;
        text-transform: uppercase; flex-shrink: 0;
    }
    .btn-nav {
        font-family: var(--font-body);
        font-size: 0.76rem; font-weight: 600;
        letter-spacing: .04em;
        padding: 6px 12px; border-radius: 10px;
        border: 1.5px solid var(--ink);
        background: transparent; color: var(--ink);
        text-decoration: none; cursor: pointer;
        transition: background .2s, color .2s;
        display: inline-flex; align-items: center; gap: 5px;
        white-space: nowrap;
    }
    .btn-nav:hover { color: var(--ink); }

    /* ── Red logout button ── */
    .btn-nav-logout {
        background-image: linear-gradient(45deg, #c0392b 0%, #922b21 100%);
        color: #fff !important;
        border-color: transparent;
    }
    .btn-nav-logout:hover {
        filter: brightness(1.1);
        color: #fff !important;
    }

    @media (max-width: 400px) {
        .btn-nav .btn-label { display: none; }
        .btn-nav { padding: 7px 10px; }
    }

    /* ── LAYOUT ── */
    .page-wrap {
        position: fixed;
        top: var(--nav-h);
        left: 0; right: 0; bottom: 0;
        display: grid;
        grid-template-columns: 380px 1fr;
        gap: var(--card-gap);
        padding: var(--card-gap);
        overflow: hidden;
    }
    @media (max-width: 960px) {
        .page-wrap { grid-template-columns: 1fr; grid-template-rows: auto 1fr; position: static; }
        body { overflow: auto; }
    }

    /* ── CARDS ── */
    .card {
        background: #fff;
        border-radius: var(--radius-lg);
        border: 1px solid var(--paper-3);
        box-shadow: var(--shadow);
        overflow-y: auto; overflow-x: hidden;
        height: 100%;
        scrollbar-width: thin;
        scrollbar-color: var(--paper-3) transparent;
    }
    .card::-webkit-scrollbar { width: 5px; }
    .card::-webkit-scrollbar-track { background: transparent; }
    .card::-webkit-scrollbar-thumb { background: var(--paper-3); border-radius: 99px; }
    @media (max-width: 960px) { .card { height: auto; overflow-y: visible; } }

    .card-header {
        padding: 28px 28px 0;
        position: sticky; top: 0;
        background: #fff; z-index: 10;
        border-bottom: 1px solid transparent;
        transition: border-color .2s;
    }
    .card.scrolled .card-header { border-bottom-color: var(--paper-3); }
    .card-body { padding: 24px 28px 28px; }
    .section-eyebrow { font-size: 0.67rem; font-weight: 600; letter-spacing: .14em; text-transform: uppercase; color: var(--accent); margin-bottom: 6px; }
    .section-title { font-family: var(--font-head); font-size: 1.6rem; line-height: 1.25; color: var(--ink); margin-bottom: 4px; }

    /* ── FORM ── */
    .form-group { margin-bottom: 18px; }
    .form-label { display: block; font-size: 0.8rem; font-weight: 600; letter-spacing: .03em; color: var(--ink-2); margin-bottom: 6px; }
    .form-control, .form-select {
        font-family: var(--font-body); font-size: 0.9rem;
        width: 100%; padding: 10px 14px;
        border: 1.5px solid var(--paper-3); border-radius: var(--radius);
        background: var(--paper); color: var(--ink);
        outline: none; transition: border-color .2s, box-shadow .2s; appearance: none;
    }
    .form-control:focus, .form-select:focus { border-color: var(--accent); background: #fff; box-shadow: 0 0 0 3px rgba(201,79,44,.12); }
    textarea.form-control { resize: vertical; min-height: 80px; }
    .select-wrap { position: relative; }
    .select-wrap::after { content: '\F282'; font-family: 'bootstrap-icons'; position: absolute; right: 14px; top: 50%; transform: translateY(-50%); color: var(--ink-3); pointer-events: none; font-size: .9rem; }
    .file-input-label { display: flex; align-items: center; gap: 10px; padding: 10px 14px; border: 1.5px dashed var(--paper-3); border-radius: var(--radius); background: var(--paper); cursor: pointer; transition: border-color .2s, background .2s; font-size: 0.85rem; color: var(--ink-3); }
    .file-input-label:hover { border-color: var(--accent); background: #fff; color: var(--ink); }
    .file-input-label i { font-size: 1.2rem; color: var(--accent); }
    #photo { display: none; }
    #photoPreview { display: none; margin-top: 10px; border-radius: var(--radius); overflow: hidden; position: relative; }
    #photoPreview img { width: 100%; max-height: 160px; object-fit: cover; display: block; }
    #photoPreviewClear { position: absolute; top: 6px; right: 6px; background: rgba(0,0,0,.5); color: #fff; border: none; border-radius: 50%; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; cursor: pointer; font-size: 1rem; transition: background .2s; }
    #photoPreviewClear:hover { background: rgba(201,79,44,.9); }

    #geotagStatus { display: none; margin-top: 8px; font-size: 0.78rem; padding: 7px 12px; border-radius: var(--radius); font-weight: 500; }
    #geotagStatus.success { display: flex; align-items: center; gap: 6px; background: rgba(45,106,79,.1); color: var(--leaf); }
    #geotagStatus.warning { display: flex; align-items: center; gap: 6px; background: rgba(193,127,36,.12); color: var(--sun); }
    #geotagStatus.info    { display: flex; align-items: center; gap: 6px; background: rgba(29,95,138,.1); color: var(--sky); }

    #pinMapWrapper { display: none; margin-top: 10px; }
    #pinMapWrapper .map-label { font-size: 0.75rem; font-weight: 500; color: var(--sky); background: rgba(29,95,138,.08); padding: 6px 12px; border-radius: var(--radius) var(--radius) 0 0; border: 1px solid rgba(29,95,138,.15); border-bottom: none; }
    #pinMap { height: 200px; width: 100%; border-radius: 0 0 var(--radius) var(--radius); border: 1px solid rgba(29,95,138,.15); }
    #pinCoords { display: none; margin-top: 4px; font-size: 0.75rem; color: var(--leaf); font-weight: 500; }

    .btn-submit { width: 100%; padding: 13px 20px; border-radius: var(--radius); border: none; background-image: linear-gradient(45deg, #8baaaa 0%, #ae8b9c 100%); color: #fff; font-family: var(--font-body); font-size: 0.9rem; font-weight: 600; letter-spacing: .03em; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; transition: background .2s, transform .1s, box-shadow .2s; box-shadow: 0 4px 16px rgba(201,79,44,.3); margin-top: 8px; }
    .btn-submit:hover { background: var(--ink-2); box-shadow: 0 6px 24px rgba(12,12,12,.4); }

    /* ── REPORT CARDS ── */
    #userReports { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }
    .report-card { border-radius: var(--radius-lg); border: 1px solid var(--paper-3); background: #fff; overflow: hidden; box-shadow: var(--shadow); transition: transform .25s, box-shadow .25s; display: flex; flex-direction: column; }
    .report-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-lg); }
    .report-card-img { width: 100%; height: 180px; object-fit: cover; display: block; background: var(--paper-2); }
    .report-card-no-img { height: 160px; display: flex; align-items: center; justify-content: center; background: var(--paper-2); }
    .report-card-no-img i { font-size: 2.5rem; color: var(--paper-3); }
    .report-card-body { padding: 16px; flex: 1; display: flex; flex-direction: column; gap: 8px; }
    .report-card-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }
    .report-category { font-family: var(--font-head); font-size: 1.05rem; line-height: 1.2; color: var(--ink); }
    .badge { display: inline-flex; align-items: center; gap: 4px; font-size: 0.68rem; font-weight: 600; letter-spacing: .06em; text-transform: uppercase; padding: 4px 10px; border-radius: 100px; flex-shrink: 0; }
    .badge-pending    { background: rgba(193,127,36,.15); color: var(--sun); }
    .badge-inprogress { background: rgba(29,95,138,.14);  color: var(--sky); }
    .badge-resolved   { background: rgba(45,106,79,.13);  color: var(--leaf); }
    .badge-rejected   { background: rgba(201,79,44,.12);  color: var(--accent); }
    .report-meta { font-size: 0.78rem; color: var(--ink-3); line-height: 1.5; display: flex; flex-direction: column; gap: 3px; margin-top: auto; }
    .report-meta span { display: flex; align-items: center; gap: 5px; }
    .report-meta i { font-size: 0.75rem; flex-shrink: 0; color: var(--accent); }
    .report-desc { font-size: 0.83rem; color: var(--ink-2); line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
    .empty-state { grid-column: 1 / -1; padding: 60px 24px; text-align: center; color: var(--ink-3); }
    .empty-state i { font-size: 3rem; display: block; margin-bottom: 12px; color: var(--paper-3); }
    .empty-state p { font-size: 0.9rem; }
    .form-divider { height: 1px; background: var(--paper-2); margin: 20px 0; }

    @keyframes fadeSlideIn { from { opacity: 0; transform: translateY(14px); } to { opacity: 1; transform: translateY(0); } }
    .card { animation: fadeSlideIn .4s ease both; }
    .page-wrap > *:nth-child(2) { animation-delay: .08s; }

    @media (max-width: 960px) { .page-wrap { padding: 16px; gap: 16px; padding-top: calc(var(--nav-h) + 16px); } }
    @media (max-width: 480px) { .card-header { padding: 20px 18px 0; } .card-body { padding: 18px 18px 22px; } .section-title { font-size: 1.3rem; } }
    </style>
</head>
<body>

<!-- ══════════ NAVBAR ══════════ -->
<nav class="nav-bar">
    <a class="nav-brand" href="#">
        <img src="./image/lgu.png" alt="Lambunao seal">
        <div class="nav-brand-text">
            <small>Municipality of</small>
            Lambunao
        </div>
    </a>

    <?php if (isset($_SESSION['firstname']) && isset($_SESSION['lastname'])): ?>
        <div class="nav-user">
            <span class="nav-welcome">
                <?php echo htmlspecialchars($_SESSION['firstname']); ?>
            </span>
            <div class="avatar" title="<?php echo htmlspecialchars($_SESSION['firstname'] . ' ' . $_SESSION['lastname']); ?>">
                <?php
                    $fi = !empty($_SESSION['firstname']) ? substr($_SESSION['firstname'], 0, 1) : '';
                    $li = !empty($_SESSION['lastname'])  ? substr($_SESSION['lastname'],  0, 1) : '';
                    echo htmlspecialchars($fi . $li);
                ?>
            </div>
            <a href="ereport.php" class="btn-nav">
                <i class="bi bi-speedometer2"></i>
                <span class="btn-label"> Dashboard</span>
            </a>
            <a href="index.php?logout=true" class="btn-nav btn-nav-logout">
                <i class="bi bi-box-arrow-right"></i>
                <span class="btn-label"> Logout</span>
            </a>
        </div>
    <?php else: ?>
        <a href="index.php" class="btn-nav">
            <i class="bi bi-person"></i>
            <span class="btn-label"> Login</span>
        </a>
    <?php endif; ?>
</nav>

<!-- ══════════ PAGE ══════════ -->
<div class="page-wrap">

    <!-- FORM CARD -->
    <div class="card" id="formCard">
        <div class="card-header">
            <p class="section-eyebrow"><i class="bi bi-broadcast me-1"></i>Community Reports</p>
            <h2 class="section-title">Submit an Issue</h2>
            <p style="font-size:.83rem; color: var(--ink-3); margin-top: 4px; padding-bottom: 20px;">
                Help us keep Lambunao safe and clean.
            </p>
            <div class="form-divider" style="margin: 0 -28px; width: calc(100% + 56px);"></div>
        </div>
        <div class="card-body">
            <form id="reportForm" onsubmit="report(event)">
                <div class="form-group">
                    <label class="form-label">Category</label>
                    <div class="select-wrap">
                        <select class="form-select" id="category" name="category" required>
                            <option value="" selected disabled>Select a category…</option>
                            <option>Road Damage</option>
                            <option>Waste Problem</option>
                            <option>Streetlight Outage</option>
                            <option>Flooding</option>
                            <option>Public Safety</option>
                            <option>Others</option>
                        </select>
                    </div>
                </div>
                <div class="form-group" id="otherCategoryDiv" style="display: none;">
                    <label class="form-label">Specify Issue</label>
                    <input type="text" class="form-control" id="otherCategory" name="otherCategory" placeholder="Describe the issue type…">
                </div>
                <div class="form-group">
                    <label class="form-label">Description</label>
                    <textarea class="form-control" id="description" name="description" rows="3" placeholder="What's happening? Be as specific as possible…" required></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">Landmark / Location</label>
                    <input type="text" class="form-control" id="location" name="location" placeholder="e.g. Near the municipal hall, etc." required>
                </div>
                <div class="form-group">
                    <label class="form-label">Photo</label>
                    <label class="file-input-label" for="photo">
                        <i class="bi bi-camera"></i>
                        <span id="fileLabel">Tap to upload a photo</span>
                    </label>
                    <input type="file" id="photo" name="photo" accept="image/*">
                    <div id="photoPreview">
                        <img id="photoPreviewImg" src="" alt="Preview">
                        <button type="button" id="photoPreviewClear" title="Remove photo"><i class="bi bi-x"></i></button>
                    </div>
                    <div id="geotagStatus"></div>
                    <div id="pinMapWrapper">
                        <div class="map-label"><i class="bi bi-pin-map-fill me-1"></i>No GPS found — <strong>click the map to pin the location</strong></div>
                        <div id="pinMap"></div>
                        <div id="pinCoords"><i class="bi bi-geo-alt-fill me-1"></i><span id="pinCoordsText"></span></div>
                    </div>
                </div>
                <input type="hidden" id="latitude"  name="latitude">
                <input type="hidden" id="longitude" name="longitude">
                <button type="submit" class="btn-submit"><i class="bi bi-send-fill"></i> Submit Report</button>
            </form>
        </div>
    </div>

    <!-- REPORTS CARD -->
    <div class="card" id="reportsCard">
        <div class="card-header">
            <p class="section-eyebrow"><i class="bi bi-clock-history me-1"></i>Your Activity</p>
            <h2 class="section-title">Submitted Reports</h2>
            <p style="font-size:.83rem; color: var(--ink-3); margin-top: 4px; padding-bottom: 20px;">
                Track the status of your community reports in real-time.
            </p>
            <div class="form-divider" style="margin: 0 -28px; width: calc(100% + 56px);"></div>
        </div>
        <div class="card-body">
            <div id="userReports"></div>
        </div>
    </div>

</div>

<!-- ══════════ SCRIPTS ══════════ -->
<script src="js/jquery.js"></script>
<script src="js/index.js"></script>
<script>
document.querySelectorAll('.card').forEach(function (card) {
    card.addEventListener('scroll', function () {
        card.classList.toggle('scrolled', card.scrollTop > 4);
    });
});

document.getElementById('photo').addEventListener('change', function () {
    const file = this.files[0];
    if (!file) return;
    document.getElementById('fileLabel').textContent = file.name;
    const reader = new FileReader();
    reader.onload = function (e) {
        document.getElementById('photoPreviewImg').src = e.target.result;
        document.getElementById('photoPreview').style.display = 'block';
    };
    reader.readAsDataURL(file);
    showGeotagStatus('info', '<i class="bi bi-hourglass-split"></i> Reading GPS from photo…');
    EXIF.getData(file, function () {
        const latDMS = EXIF.getTag(this, 'GPSLatitude');
        const latRef = EXIF.getTag(this, 'GPSLatitudeRef');
        const lngDMS = EXIF.getTag(this, 'GPSLongitude');
        const lngRef = EXIF.getTag(this, 'GPSLongitudeRef');
        if (latDMS && lngDMS) {
            const lat = dmsToDecimal(latDMS, latRef);
            const lng = dmsToDecimal(lngDMS, lngRef);
            if (lat !== null && lng !== null) {
                document.getElementById('latitude').value  = lat;
                document.getElementById('longitude').value = lng;
                showGeotagStatus('success', `<i class="bi bi-geo-alt-fill"></i> GPS: ${lat.toFixed(5)}, ${lng.toFixed(5)}`);
                hidePinMap(); return;
            }
        }
        showGeotagStatus('warning', '<i class="bi bi-pin-map"></i> No GPS in photo — pin location on map below');
        showPinMap();
    });
});

document.getElementById('photoPreviewClear').addEventListener('click', function () {
    document.getElementById('photo').value = '';
    document.getElementById('photoPreview').style.display = 'none';
    document.getElementById('fileLabel').textContent = 'Tap to upload a photo';
    document.getElementById('geotagStatus').className = '';
    document.getElementById('geotagStatus').innerHTML = '';
    hidePinMap();
});

let pinMap = null, pinMarker = null;

function initPinMap(lat, lng) {
    if (pinMap) { pinMap.setView([lat, lng], 14); return; }
    pinMap = L.map('pinMap').setView([lat, lng], 14);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '© OpenStreetMap contributors' }).addTo(pinMap);
    pinMap.on('click', function (e) {
        const { lat, lng } = e.latlng;
        if (pinMarker) { pinMarker.setLatLng([lat, lng]); }
        else {
            pinMarker = L.marker([lat, lng], { draggable: true }).addTo(pinMap);
            pinMarker.on('dragend', function () { const p = pinMarker.getLatLng(); setManualCoords(p.lat, p.lng); });
        }
        setManualCoords(lat, lng);
    });
}

function setManualCoords(lat, lng) {
    document.getElementById('latitude').value  = lat;
    document.getElementById('longitude').value = lng;
    document.getElementById('pinCoordsText').textContent = `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
    document.getElementById('pinCoords').style.display = 'flex';
}

function showPinMap() {
    document.getElementById('pinMapWrapper').style.display = 'block';
    const dfLat = 11.0506, dfLng = 122.4764;
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            p => { initPinMap(p.coords.latitude, p.coords.longitude); document.getElementById('latitude').value = p.coords.latitude; document.getElementById('longitude').value = p.coords.longitude; },
            ()  => { initPinMap(dfLat, dfLng); document.getElementById('latitude').value = dfLat; document.getElementById('longitude').value = dfLng; }
        );
    } else {
        initPinMap(dfLat, dfLng);
        document.getElementById('latitude').value = dfLat;
        document.getElementById('longitude').value = dfLng;
    }
    setTimeout(() => { if (pinMap) pinMap.invalidateSize(); }, 200);
}

function hidePinMap() {
    document.getElementById('pinMapWrapper').style.display = 'none';
    document.getElementById('pinCoords').style.display = 'none';
}

function showGeotagStatus(type, msg) {
    const el = document.getElementById('geotagStatus');
    el.className = type;
    el.innerHTML = msg;
}

function dmsToDecimal(dms, ref) {
    if (!dms || dms.length < 3) return null;
    const d = dms[0].numerator / dms[0].denominator;
    const m = dms[1].numerator / dms[1].denominator;
    const s = dms[2].numerator / dms[2].denominator;
    let dec = d + (m / 60) + (s / 3600);
    if (ref === 'S' || ref === 'W') dec = -dec;
    return dec;
}

$(document).ready(function () {
    $("#category").on("change", function () {
        if ($(this).val() === "Others") {
            $("#otherCategoryDiv").show();
            $("#otherCategory").prop("required", true);
        } else {
            $("#otherCategoryDiv").hide();
            $("#otherCategory").prop("required", false).val("");
        }
    });
    loadUserReports();
    setInterval(loadUserReports, 5000);
});

(function prefillCoords() {
    document.getElementById('latitude').value  = 11.0506;
    document.getElementById('longitude').value = 122.4764;
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function (p) {
            document.getElementById('latitude').value  = p.coords.latitude;
            document.getElementById('longitude').value = p.coords.longitude;
        });
    }
})();

let latestUserReportId = 0;
let reportStatuses = {};

function loadUserReports() {
    $.get("./php/get_user_reports.php", function (data) {
        let parsed = JSON.parse(data);
        if (parsed.status === "success") {
            parsed.reports.forEach(r => { reportStatuses[r.reportID] = normalizeStatus(r.status || 'pending'); });
            latestUserReportId = parsed.reports.length ? parsed.reports[0].reportID : 0;
            displayReports(parsed.reports);
        }
    });
}

function normalizeStatus(status) {
    return (status || 'pending').trim().toLowerCase().replace(/\s+/g, '-');
}

function getStatusBadge(status) {
    const n = normalizeStatus(status);
    const map = {
        'pending':     { cls: 'badge-pending',    icon: 'bi-clock',        label: 'Pending' },
        'in-progress': { cls: 'badge-inprogress', icon: 'bi-arrow-repeat', label: 'In Progress' },
        'in-progres':  { cls: 'badge-inprogress', icon: 'bi-arrow-repeat', label: 'In Progress' },
        'resolved':    { cls: 'badge-resolved',   icon: 'bi-check-circle', label: 'Resolved' },
        'rejected':    { cls: 'badge-rejected',   icon: 'bi-x-circle',     label: 'Rejected' },
    };
    const s = map[n] || map['pending'];
    return `<span class="badge ${s.cls}"><i class="bi ${s.icon}"></i> ${s.label}</span>`;
}

function displayReports(reports) {
    const container = $('#userReports');
    container.empty();
    if (!reports.length) {
        container.html(`<div class="empty-state"><i class="bi bi-inbox"></i><p>No reports submitted yet.<br>Use the form to flag an issue in your community.</p></div>`);
        reportStatuses = {}; latestUserReportId = 0; return;
    }
    reports.forEach(function (r) {
        const status = r.status || 'pending';
        reportStatuses[r.reportID] = status;
        const photoHtml = r.photo ? `<img class="report-card-img" src="${r.photo}" alt="Report photo">` : `<div class="report-card-no-img"><i class="bi bi-image"></i></div>`;
        const time = r.timestamp ? new Date(r.timestamp).toLocaleString('en-PH', { dateStyle: 'medium', timeStyle: 'short' }) : '—';
        container.append(`
            <div class="report-card">
                ${photoHtml}
                <div class="report-card-body">
                    <div class="report-card-top">
                        <span class="report-category">${r.category}</span>
                        ${getStatusBadge(status)}
                    </div>
                    <p class="report-desc">${r.description}</p>
                    <div class="report-meta">
                        <span><i class="bi bi-geo-alt-fill"></i>${r.location}</span>
                        <span><i class="bi bi-clock"></i>${time}</span>
                    </div>
                </div>
            </div>`);
    });
}

function report(event) {
    event.preventDefault();
    const submitBtn = document.querySelector('.btn-submit');
    submitBtn.disabled = true;
    const originalBtnHtml = submitBtn.innerHTML;
    submitBtn.innerHTML = '<i class="bi bi-hourglass-split"></i> Submitting...';
    const form = document.getElementById('reportForm');
    const formData = new FormData(form);
    const category = document.getElementById('category').value;
    formData.append('category', category);
    if (category === 'Others') formData.append('otherCategory', document.getElementById('otherCategory').value);
    const lat = document.getElementById('latitude').value;
    const lng = document.getElementById('longitude').value;
    if (lat && lng) { formData.append('latitude', lat); formData.append('longitude', lng); }
    const photoFile = document.getElementById('photo').files[0];
    if (photoFile) formData.append('photo', photoFile);
    $.ajax({
        url: './php/report.php', type: 'POST', data: formData,
        processData: false, contentType: false, dataType: 'json',
        success: function(response) {
            if (response.status === 'success') {
                const statusDiv = document.getElementById('geotagStatus');
                statusDiv.className = 'success';
                statusDiv.innerHTML = '<i class="bi bi-check-circle-fill"></i> Report submitted successfully! Form cleared.';
                statusDiv.style.display = 'flex';
                setTimeout(() => { statusDiv.style.display = 'none'; }, 3000);
                form.reset();
                document.getElementById('photo').value = '';
                document.getElementById('fileLabel').textContent = 'Tap to upload a photo';
                document.getElementById('photoPreview').style.display = 'none';
                document.getElementById('photoPreviewImg').src = '';
                showGeotagStatus('info', '');
                document.getElementById('geotagStatus').style.display = 'none';
                document.getElementById('latitude').value  = '11.0506';
                document.getElementById('longitude').value = '122.4764';
                if (pinMap && pinMarker) { pinMap.removeLayer(pinMarker); pinMarker = null; }
                hidePinMap();
                document.getElementById('otherCategory').value = '';
                document.getElementById('otherCategoryDiv').style.display = 'none';
                const catSelect = document.getElementById('category');
                catSelect.value = '';
                $(catSelect).trigger('change');
                document.getElementById('pinCoords').style.display = 'none';
                document.getElementById('pinCoordsText').innerHTML = '';
                loadUserReports();
                document.getElementById('formCard').scrollTo({ top: 0, behavior: 'smooth' });
            } else {
                showGeotagStatus('warning', '<i class="bi bi-exclamation-triangle-fill"></i> ' + (response.message || 'Submission failed. Please try again.'));
                document.getElementById('geotagStatus').style.display = 'flex';
            }
        },
        error: function() {
            showGeotagStatus('warning', '<i class="bi bi-exclamation-triangle-fill"></i> Network error. Please check your connection.');
            document.getElementById('geotagStatus').style.display = 'flex';
        },
        complete: function() { submitBtn.disabled = false; submitBtn.innerHTML = originalBtnHtml; }
    });
}
</script>
</body>
</html>