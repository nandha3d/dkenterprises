import React, { useEffect, useRef } from 'react';
import { Vehicle } from '../types';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

interface LeafletFleetMapProps {
  vehicles: Vehicle[];
  highlightVehicleId?: number;
  height?: string;
}

export const LeafletFleetMap: React.FC<LeafletFleetMapProps> = ({
  vehicles,
  highlightVehicleId,
  height = '380px'
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersRef = useRef<{ [key: number]: L.Marker }>({});

  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      // Center around Coimbatore / Tirupur region (Tamil Nadu)
      const map = L.map(mapContainerRef.current, {
        center: [11.025, 76.975],
        zoom: 12,
        zoomControl: true
      });

      // CartoDB Dark Matter / OpenStreetMap tiles (Dark Tactical Theme)
      L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
        subdomains: 'abcd',
        maxZoom: 19
      }).addTo(map);

      // Add Geofence circles
      // 1. Main RO Water Treatment Plant
      L.circle([11.010, 76.945], {
        color: '#10B981',
        fillColor: '#10B981',
        fillOpacity: 0.15,
        radius: 400
      }).addTo(map).bindPopup('<b>Main RO Water Plant</b><br/>Loading & Bottling Station');

      // 2. Texvalley Corporate Campus
      L.circle([11.042, 77.011], {
        color: '#38BDF8',
        fillColor: '#38BDF8',
        fillOpacity: 0.15,
        radius: 500
      }).addTo(map).bindPopup('<b>Texvalley Corporate Campus</b><br/>Bulk 88KL Delivery Geofence');

      // 3. Amirtha Milk Dairy
      L.circle([11.025, 76.982], {
        color: '#A855F7',
        fillColor: '#A855F7',
        fillOpacity: 0.15,
        radius: 350
      }).addTo(map).bindPopup('<b>Amirtha Milk Dairy</b><br/>15-Day Corporate Cycle');

      mapInstanceRef.current = map;
    }

    const map = mapInstanceRef.current;

    // Clear old markers
    Object.values(markersRef.current).forEach(m => m.remove());
    markersRef.current = {};

    // Create custom SVG markers for each vehicle
    vehicles.forEach(v => {
      const isTanker = v.vehicle_type === 'tanker';
      const isMoving = v.status === 'moving';
      const color = isTanker ? '#0284C7' : '#0D9488';
      const haloColor = isMoving ? '#10B981' : '#F59E0B';

      const customIcon = L.divIcon({
        className: 'custom-fleet-marker',
        html: `
          <div style="position: relative; display: flex; flex-direction: column; align-items: center;">
            <div style="
              width: 32px;
              height: 32px;
              background: ${color};
              border: 2px solid #FFFFFF;
              border-radius: 8px;
              box-shadow: 0 0 12px ${haloColor};
              display: flex;
              align-items: center;
              justify-content: center;
              color: white;
              font-weight: 800;
              font-size: 11px;
            ">
              ${isTanker ? '🚛' : '💧'}
            </div>
            <div style="
              background: rgba(11, 15, 23, 0.9);
              color: #F8FAFC;
              font-size: 9px;
              font-weight: 700;
              padding: 1px 5px;
              border-radius: 4px;
              border: 1px solid #334155;
              white-space: nowrap;
              margin-top: 2px;
            ">
              ${v.vehicle_number}
            </div>
          </div>
        `,
        iconSize: [60, 45],
        iconAnchor: [30, 22]
      });

      const marker = L.marker([v.last_latitude, v.last_longitude], { icon: customIcon })
        .addTo(map)
        .bindPopup(`
          <div style="font-family: sans-serif; min-width: 180px; color: #111;">
            <h4 style="margin: 0 0 4px 0; color: #0284C7;">${v.vehicle_number}</h4>
            <p style="margin: 0; font-size: 11px; color: #555;">
              <b>Type:</b> ${isTanker ? (v.capacity_kl + ' KL Tanker') : 'Tata Ace Can Truck'}<br/>
              <b>Driver:</b> ${v.driver_name} (${v.driver_phone})<br/>
              <b>Speed:</b> ${v.last_speed_kmh} km/h (${v.status})<br/>
              <b>Current:</b> ${v.current_trip || 'In Transit'}
            </p>
          </div>
        `);

      markersRef.current[v.id] = marker;

      if (highlightVehicleId && v.id === highlightVehicleId) {
        marker.openPopup();
        map.panTo([v.last_latitude, v.last_longitude]);
      }
    });

  }, [vehicles, highlightVehicleId]);

  return (
    <div style={{ position: 'relative', width: '100%' }}>
      <div ref={mapContainerRef} style={{ height, width: '100%', borderRadius: '10px' }} />
      <div style={{
        position: 'absolute',
        bottom: '10px',
        left: '10px',
        zIndex: 1000,
        background: 'rgba(15, 23, 42, 0.85)',
        border: '1px solid #334155',
        borderRadius: '6px',
        padding: '4px 8px',
        fontSize: '10px',
        color: '#94A3B8',
        pointerEvents: 'none'
      }}>
        OpenStreetMap Vector · Zero Google Maps Recurring Fee
      </div>
    </div>
  );
};
