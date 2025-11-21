let currentVehicles = [];
let currentGarageIndex = null;
let isSociety = false;

// Image fallback handler
let imageAttempts = {};

function handleImageError(img) {
    const modelName = img.getAttribute('data-model');
    console.log('[GARAGE] Image failed to load for:', modelName);
    
    if (!imageAttempts[modelName]) {
        imageAttempts[modelName] = 0;
    }
    
    const fallbacks = [
        `https://docs.fivem.net/vehicles/${modelName}.webp`,
        `vehicles/${modelName}.webp`,
        `vehicles/${modelName}.png`,
        `vehicles/${modelName}.jpg`,
        `https://docs.fivem.net/vehicles/adder.webp`
    ];
    
    imageAttempts[modelName]++;
    
    if (imageAttempts[modelName] < fallbacks.length) {
        console.log('[GARAGE] Trying fallback:', fallbacks[imageAttempts[modelName]]);
        img.src = fallbacks[imageAttempts[modelName]];
    } else {
        // All fallbacks failed, show placeholder icon
        console.log('[GARAGE] All fallbacks failed, showing icon');
        img.style.display = 'none';
        const container = img.parentElement;
        if (container && !container.querySelector('.fallback-icon')) {
            container.innerHTML = `
                <div class="fallback-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 16H9m10 0h3v-3.15a1 1 0 0 0-.84-.99L16 11l-2.7-3.6a1 1 0 0 0-.8-.4H5.24a2 2 0 0 0-1.8 1.1l-.8 1.63A6 6 0 0 0 2 12.42V16h2"></path>
                        <circle cx="6.5" cy="16.5" r="2.5"></circle>
                        <circle cx="16.5" cy="16.5" r="2.5"></circle>
                    </svg>
                </div>
            `;
        }
    }
}

$(document).ready(function() {
    // Listen for NUI messages
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.action === 'openGarage') {
            openGarage(data.vehicles, data.garageIndex, data.society, data.allowTransfer);
        } else if (data.action === 'closeGarage') {
            closeGarage();
        }
    });

    // Close on ESC key
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            if (!$('#transfer-modal').hasClass('hidden')) {
                closeTransferModal();
            } else {
                closeGarage();
            }
        }
    });

    // Search functionality
    $('#search-input').on('input', function() {
        const searchTerm = $(this).val().toLowerCase();
        filterVehicles(searchTerm);
    });
});

function openGarage(vehicles, garageIndex, society, allowTransfer) {
    currentVehicles = vehicles;
    currentGarageIndex = garageIndex;
    isSociety = society || false;
    transferAllowed = allowTransfer !== false; // Default to true if not specified
    
    $('#garage-container').removeClass('hidden');
    $('#search-input').val('');
    renderVehicles(vehicles);
    
    // Enable cursor
    $.post('https://lunar_garage/enableCursor', JSON.stringify({}));
}

function closeGarage() {
    $('#garage-container').addClass('hidden');
    currentVehicles = [];
    currentGarageIndex = null;
    
    // Disable cursor and notify Lua
    $.post('https://lunar_garage/closeUI', JSON.stringify({}));
}

function renderVehicles(vehicles) {
    const container = $('#vehicles-list');
    container.empty();
    
    if (vehicles.length === 0) {
        container.html('<div class="no-vehicles">No vehicles found</div>');
        $('#vehicle-count').text('Total vehicles: 0');
        return;
    }
    
    $('#vehicle-count').text(`Total vehicles: ${vehicles.length}`);
    
    vehicles.forEach((vehicle, index) => {
        const vehicleElement = createVehicleElement(vehicle, index);
        container.append(vehicleElement);
    });
}

function createVehicleElement(vehicle, index) {
    const fuelLevel = vehicle.fuelLevel || 100;
    const engineHealth = vehicle.engineHealth || 1000;
    const bodyHealth = vehicle.bodyHealth || 1000;
    
    const fuelPercent = Math.round(fuelLevel);
    const enginePercent = Math.round((engineHealth / 1000) * 100);
    const bodyPercent = Math.round((bodyHealth / 1000) * 100);
    
    const statusText = getStatusText(vehicle.state);
    
    // Determine button text and icon based on state
    let buttonText, buttonIcon, buttonClass;
    if (vehicle.state === 'in_impound') {
        buttonText = 'Retrieve';
        buttonIcon = getIcon('package-check');
        buttonClass = 'btn-retrieve';
    } else if (vehicle.state === 'out_garage') {
        buttonText = 'Locate';
        buttonIcon = getIcon('map-pin');
        buttonClass = 'btn-locate';
    } else {
        buttonText = 'Take Out';
        buttonIcon = getIcon('car-front');
        buttonClass = 'btn-takeout';
    }
    
    // Determine status class for styling
    let statusClass = 'available';
    if (vehicle.state === 'out_garage') statusClass = 'out';
    if (vehicle.state === 'in_impound') statusClass = 'impounded';
    
    // Get vehicle image URL
    const vehicleImage = getVehicleImage(vehicle);
    const modelName = (vehicle.modelName || 'adder').toLowerCase();
    
    const vehicleHtml = `
        <div class="vehicle-item" data-index="${index}">
            <div class="vehicle-header">
                <div class="vehicle-info">
                    <div class="vehicle-image-container">
                        <img src="${vehicleImage}" 
                             alt="${vehicle.label}" 
                             class="vehicle-image" 
                             data-model="${modelName}"
                             onerror="handleImageError(this)">
                    </div>
                    <div class="vehicle-text">
                        <div class="vehicle-name">${vehicle.label}</div>
                        <div class="vehicle-status ${statusClass}">${statusText}</div>
                    </div>
                </div>
                <div class="vehicle-plate">${vehicle.plate}</div>
            </div>
            <div class="vehicle-details">
                <div class="stats-container">
                    <div class="stat-bar">
                        <div class="stat-label">
                            <div class="stat-label-left">
                                ${getIcon('fuel', 'stat-icon')}
                                <span>Fuel</span>
                            </div>
                            <span class="stat-value" data-value="${fuelPercent}">0%</span>
                        </div>
                        <div class="stat-progress">
                            <div class="stat-fill fuel" style="--fill-width: ${fuelPercent}%" data-percent="${fuelPercent}"></div>
                        </div>
                    </div>
                    <div class="stat-bar">
                        <div class="stat-label">
                            <div class="stat-label-left">
                                ${getIcon('settings', 'stat-icon')}
                                <span>Engine</span>
                            </div>
                            <span class="stat-value" data-value="${enginePercent}">0%</span>
                        </div>
                        <div class="stat-progress">
                            <div class="stat-fill engine" style="--fill-width: ${enginePercent}%" data-percent="${enginePercent}"></div>
                        </div>
                    </div>
                    <div class="stat-bar">
                        <div class="stat-label">
                            <div class="stat-label-left">
                                ${getIcon('shield', 'stat-icon')}
                                <span>Body</span>
                            </div>
                            <span class="stat-value" data-value="${bodyPercent}">0%</span>
                        </div>
                        <div class="stat-progress">
                            <div class="stat-fill body" style="--fill-width: ${bodyPercent}%" data-percent="${bodyPercent}"></div>
                        </div>
                    </div>
                </div>
                <div class="actions-container">
                    <button class="action-btn ${buttonClass}" 
                            data-action="takeout" 
                            data-index="${index}"
                            data-state="${vehicle.state}">
                        ${buttonIcon}
                        ${buttonText}
                    </button>
                    <button class="action-btn btn-transfer" 
                            data-action="transfer" 
                            data-index="${index}"
                            ${vehicle.state !== 'in_garage' ? 'disabled title="Vehicle must be in garage to transfer"' : ''}>
                        ${getIcon('arrow-right-left')}
                        Transfer
                    </button>
                </div>
            </div>
        </div>
    `;
    
    const $element = $(vehicleHtml);
    
    // Toggle expand on header click
    $element.find('.vehicle-header').click(function(e) {
        e.stopPropagation();
        const wasExpanded = $element.hasClass('expanded');
        $element.toggleClass('expanded');
        
        // Trigger animations when expanding
        if (!wasExpanded) {
            setTimeout(() => {
                animateStats($element);
            }, 100);
        }
    });
    
    // Action buttons
    $element.find('.action-btn').click(function(e) {
        e.stopPropagation();
        const action = $(this).data('action');
        const vehicleIndex = $(this).data('index');
        handleAction(action, vehicleIndex);
    });
    
    return $element;
}

function animateStats($element) {
    // Animate stat values (percentage numbers)
    $element.find('.stat-value').each(function() {
        const $this = $(this);
        const targetValue = parseInt($this.data('value'));
        let currentValue = 0;
        const duration = 1500; // 1.5 seconds
        const steps = 60;
        const increment = targetValue / steps;
        const stepDuration = duration / steps;
        
        const counter = setInterval(() => {
            currentValue += increment;
            if (currentValue >= targetValue) {
                currentValue = targetValue;
                clearInterval(counter);
            }
            $this.text(Math.round(currentValue) + '%');
        }, stepDuration);
    });
    
    // Trigger CSS animations for bars by adding a class
    $element.find('.stat-fill').each(function() {
        const $this = $(this);
        // Force reflow to restart animation
        $this.css('animation', 'none');
        setTimeout(() => {
            $this.css('animation', '');
        }, 10);
    });
}

function getVehicleImage(vehicle) {
    // Priority 1: Database custom image URL
    if (vehicle.customImage && vehicle.customImage.trim() !== '') {
        console.log('[GARAGE] Using custom image:', vehicle.customImage);
        return vehicle.customImage;
    }
    
    const modelName = (vehicle.modelName || 'adder').toLowerCase();
    console.log('[GARAGE] Loading image for model:', modelName);
    
    // Priority 2: FiveM CDN (most reliable for default vehicles)
    const fivemImage = `https://docs.fivem.net/vehicles/${modelName}.webp`;
    console.log('[GARAGE] Image URL:', fivemImage);
    
    return fivemImage;
}

function getVehicleImageFallbacks(modelName) {
    modelName = (modelName || 'adder').toLowerCase();
    return [
        `vehicles/${modelName}.webp`,
        `vehicles/${modelName}.png`,
        `vehicles/${modelName}.jpg`,
        `vehicles/${modelName}.jpeg`,
        `https://docs.fivem.net/vehicles/${modelName}.webp`,
        'vehicles/placeholder.png'
    ];
}

function getIcon(name, className = '') {
    const icons = {
        'car': '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 16H9m10 0h3v-3.15a1 1 0 0 0-.84-.99L16 11l-2.7-3.6a1 1 0 0 0-.8-.4H5.24a2 2 0 0 0-1.8 1.1l-.8 1.63A6 6 0 0 0 2 12.42V16h2"></path><circle cx="6.5" cy="16.5" r="2.5"></circle><circle cx="16.5" cy="16.5" r="2.5"></circle></svg>',
        'car-front': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21 8-2 2-1.5-3.7A2 2 0 0 0 15.646 5H8.4a2 2 0 0 0-1.903 1.257L5 10 3 8"></path><path d="M7 14h.01"></path><path d="M17 14h.01"></path><rect width="18" height="8" x="3" y="10" rx="2"></rect><path d="M5 18v2"></path><path d="M19 18v2"></path></svg>',
        'fuel': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" x2="15" y1="22" y2="22"></line><line x1="4" x2="14" y1="9" y2="9"></line><path d="M14 22V4a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v18"></path><path d="M14 13h2a2 2 0 0 1 2 2v2a2 2 0 0 0 2 2h0a2 2 0 0 0 2-2V9.83a2 2 0 0 0-.59-1.42L18 5"></path></svg>',
        'settings': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"></path><circle cx="12" cy="12" r="3"></circle></svg>',
        'shield': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"></path></svg>',
        'map-pin': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"></path><circle cx="12" cy="10" r="3"></circle></svg>',
        'package-check': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 16 2 2 4-4"></path><path d="M21 10V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l2-1.14"></path><path d="M7.5 4.27l9 5.15"></path><polyline points="3.29 7 12 12 20.71 7"></polyline><line x1="12" x2="12" y1="22" y2="12"></line></svg>',
        'arrow-right-left': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 3 4 4-4 4"></path><path d="M20 7H4"></path><path d="m8 21-4-4 4-4"></path><path d="M4 17h16"></path></svg>'
    };
    
    return `<span class="${className}">${icons[name] || icons['car']}</span>`;
}

function getStatusText(state) {
    switch(state) {
        case 'in_garage':
            return '✓ Available in Garage';
        case 'out_garage':
            return '📍 Vehicle is Out - Click Locate';
        case 'in_impound':
            return '🚫 Vehicle Not Found - Impounded';
        default:
            return 'Unknown';
    }
}

let currentTransferVehicle = null;
let transferAllowed = true;

function handleAction(action, vehicleIndex) {
    const vehicle = currentVehicles[vehicleIndex];
    
    if (action === 'takeout') {
        if (vehicle.state === 'in_garage') {
            $.post('https://lunar_garage/takeOutVehicle', JSON.stringify({
                garageIndex: currentGarageIndex,
                vehicle: vehicle
            }));
            closeGarage();
        } else if (vehicle.state === 'in_impound') {
            $.post('https://lunar_garage/takeOutVehicle', JSON.stringify({
                garageIndex: currentGarageIndex,
                vehicle: vehicle
            }));
            closeGarage();
        } else if (vehicle.state === 'out_garage') {
            $.post('https://lunar_garage/locateVehicle', JSON.stringify({
                vehicle: vehicle
            }));
        }
    } else if (action === 'transfer') {
        if (!transferAllowed) {
            $.post('https://lunar_garage/showNotification', JSON.stringify({
                message: 'Vehicle transfer is disabled',
                type: 'error'
            }));
            return;
        }
        openTransferModal(vehicle);
    }
}

function openTransferModal(vehicle) {
    currentTransferVehicle = vehicle;
    
    // Set vehicle info in modal
    $('#transfer-vehicle-name').text(vehicle.label);
    $('#transfer-vehicle-plate').text(vehicle.plate);
    
    // Set vehicle image with error handling
    const vehicleImage = getVehicleImage(vehicle);
    const modelName = (vehicle.modelName || 'adder').toLowerCase();
    $('#transfer-vehicle-image')
        .attr('src', vehicleImage)
        .attr('data-model', modelName)
        .attr('onerror', 'handleImageError(this)');
    
    // Clear input
    $('#target-player-id').val('');
    
    // Show modal
    $('#transfer-modal').removeClass('hidden');
}

function closeTransferModal() {
    $('#transfer-modal').addClass('hidden');
    currentTransferVehicle = null;
}

function confirmTransfer() {
    const targetPlayerId = $('#target-player-id').val();
    
    if (!targetPlayerId || targetPlayerId < 1) {
        $.post('https://lunar_garage/showNotification', JSON.stringify({
            message: 'Please enter a valid player server ID',
            type: 'error'
        }));
        return;
    }
    
    if (!currentTransferVehicle) {
        closeTransferModal();
        return;
    }
    
    // Send transfer request to server
    $.post('https://lunar_garage/transferVehicle', JSON.stringify({
        vehicle: currentTransferVehicle,
        targetPlayerId: parseInt(targetPlayerId)
    }));
    
    closeTransferModal();
    closeGarage();
}

function filterVehicles(searchTerm) {
    if (!searchTerm) {
        renderVehicles(currentVehicles);
        return;
    }
    
    const filtered = currentVehicles.filter(vehicle => {
        const label = vehicle.label.toLowerCase();
        const plate = vehicle.plate.toLowerCase();
        return label.includes(searchTerm) || plate.includes(searchTerm);
    });
    
    renderVehicles(filtered);
}
