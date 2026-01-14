// Filter for instantaneous power sensors (W) - exclude cumulative energy (kWh)
const items = $input.all();

const powerSensors = items.filter(item => {
  const entity = item.json;

  if (!entity || !entity.entity_id) return false;

  const id = entity.entity_id.toLowerCase();
  const state = entity.state;
  const deviceClass = entity.attributes?.device_class?.toLowerCase() || '';
  const unit = entity.attributes?.unit_of_measurement?.toLowerCase() || '';

  // Include only current_consumption sensors (Tapo real-time watts)
  // OR sensors with device_class "power" and unit "w"
  const isCurrentConsumption = id.includes('current_consumption') || id.includes('current_power');
  const isPowerInWatts = deviceClass === 'power' && unit === 'w';

  // Exclude energy sensors (kWh totals)
  const isEnergySensor = deviceClass === 'energy' || unit === 'kwh';

  // Valid state check
  const hasValidState = state !== 'unavailable' && state !== 'unknown' && state !== null && !isNaN(parseFloat(state));

  return (isCurrentConsumption || isPowerInWatts) && !isEnergySensor && hasValidState;
});

return powerSensors;
