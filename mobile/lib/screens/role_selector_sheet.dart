import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class RoleSelectorSheet extends StatefulWidget {
  final bool isTamil;
  final UserRole currentRole;
  final CompanyVertical currentVertical;
  final ValueChanged<UserRole> onSelectRole;
  final ValueChanged<CompanyVertical> onSelectVertical;

  const RoleSelectorSheet({
    super.key,
    required this.isTamil,
    required this.currentRole,
    required this.currentVertical,
    required this.onSelectRole,
    required this.onSelectVertical,
  });

  @override
  State<RoleSelectorSheet> createState() => _RoleSelectorSheetState();
}

class _RoleSelectorSheetState extends State<RoleSelectorSheet> {
  String _activeUrl = ApiService.activeBaseUrl;

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t ? 'பயனர் பங்கு & நிறுவனத் தேர்வு' : 'Role & Enterprise Switcher',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t ? 'வாடிக்கையாளர் சோதனைக்காக உடனடியாக மாற்றிப் பாருங்கள்' : 'Instant 1-Tap Switching for Client Demo & Testing',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // API Server Environment Selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_done, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          t ? 'இணைக்கப்பட்ட கிளவுட் ஏபிஐ' : 'Active Cloud API Target',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('LIVE 200 OK', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _activeUrl,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ApiService.liveProductionUrl,
                      child: Text('🌐 Live Server: dkenterprises.animazon.in'),
                    ),
                    DropdownMenuItem(
                      value: ApiService.localEmulatorUrl,
                      child: Text('💻 Localhost Emulator: 10.0.2.2:8080'),
                    ),
                    DropdownMenuItem(
                      value: ApiService.localWebUrl,
                      child: Text('🖥️ Localhost Web: 127.0.0.1:8080'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _activeUrl = val);
                      ApiService.switchEndpoint(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Target API switched to: $val')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Role selection list
          Text(
            t ? 'செயல்பாட்டு பங்கு (Roles):' : 'Select Operational Role:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: UserRole.values.map((role) {
                final isSelected = widget.currentRole == role;
                return InkWell(
                  onTap: () {
                    widget.onSelectRole(role);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? role.color.withOpacity(0.15) : const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? role.color : const Color(0xFF1E293B),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: role.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(role.icon, color: role.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.title(t),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected ? role.color : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role.description(t),
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: role.color, size: 18)
                        else
                          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
