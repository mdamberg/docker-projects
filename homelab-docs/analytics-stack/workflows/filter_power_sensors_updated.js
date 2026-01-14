// Filter for instantaneous power sensors (W) - exclude cumulative energy (kWh)
const items = $input.all();

const powerSensors = items.filter(item => {
  const entity = item.json;

  // Safety checks
  if (!entity || !entity.entity_id) return false;

  const id = entity.entity_id.toLowerCase();
  const state = entity.state;
  const deviceClass = entity.attributes?.device_class?.toLowerCase();
  const unit = entity.attributes?.unit_of_measurement?.toLowerCase();

  // Include if:
  // 1. Has "current_consumption" or "current_power" in entity_id (Tapo real-time sensors)
  // 2. OR has device_class "power" with unit "w" (instantaneous watts)
  // 3. Exclude if it's an energy sensor (device_class "energy" or unit "kwh")

  const isCurrentConsumption = id.includes('current_consumption') || id.includes('current_power');
  const isPowerSensor = deviceClass === 'power' && unit === 'w';
  const isEnergySensor = deviceClass === 'energy' || unit === 'kwh';

  const isPowerOrEnergyRelated = id.includes('power') || id.includes('energy') || id.includes('watt') || id.includes('consumption');

  // Valid state check
  const hasValidState = state !== 'unavailable' && state !== 'unknown' && state !== null && !isNaN(parseFloat(state));

  // Include if it's a current consumption/power sensor OR a power sensor in watts, but NOT an energy sensor
  return (isCurrentConsumption || (isPowerSensor && isPowerOrEnergyRelated)) && !isEnergySensor && hasValidState;
});

return powerSensors;
