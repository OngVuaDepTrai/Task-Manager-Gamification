import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoMo Clone',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily:
            'Roboto', // Sử dụng font mặc định hoặc thay bằng font của bạn
      ),
      home: const MoMoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MoMoHomePage extends StatelessWidget {
  const MoMoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // 1. Lưới Dịch vụ (Top Grid)
              _buildTopServicesGrid(),
              const SizedBox(height: 10),

              // 2. Sự kiện đang diễn ra
              _buildSectionTitle('Sự kiện đang diễn ra'),
              _buildEventBanner(),
              const SizedBox(height: 15),

              // 3. MoMo đề xuất
              _buildSectionTitle('MoMo đề xuất'),
              _buildRecommendedServices(),

              // Thanh cuộn ngang mô phỏng (dấu chấm)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 15),
                  width: 30,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 4. Banner Gieo quẻ AI
              _buildAIBanner(),
              const SizedBox(height: 15),

              // 5. Có thể bạn quan tâm
              _buildSectionTitle('Có thể bạn quan tâm'),
              const SizedBox(height: 20), // Khoảng trống phụ
            ],
          ),
        ),
      ),

      // 6. Custom Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Widget Tiêu đề các mục
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Widget Lưới dịch vụ phía trên (3 hàng, 4 cột)
  Widget _buildTopServicesGrid() {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Chuyển tiền',
        'icon': Icons.paid_outlined,
        'color': Colors.red,
      },
      {
        'title': 'Thanh toán\nhóa đơn',
        'icon': Icons.receipt_long,
        'color': Colors.cyan,
      },
      {
        'title': 'Nạp tiền điện\nthoại',
        'icon': Icons.install_mobile,
        'color': Colors.blue,
      },
      {
        'title': 'Mua mã thẻ di\nđộng',
        'icon': Icons.sim_card_outlined,
        'color': Colors.orange,
      },
      {
        'title': 'Heo Đất MoMo',
        'icon': Icons.savings_outlined,
        'color': Colors.pinkAccent,
      },
      {
        'title': 'Đi bộ cùng\nMoMo',
        'icon': Icons.directions_walk,
        'color': Colors.green,
      },
      {
        'title': 'Thanh toán\nnước',
        'icon': Icons.water_drop_outlined,
        'color': Colors.blue,
      },
      {
        'title': 'Quản lý chi\ntiêu',
        'icon': Icons.account_balance_wallet_outlined,
        'color': Colors.teal,
      },
      {
        'title': 'Quỹ nhóm',
        'icon': Icons.groups_outlined,
        'color': Colors.pink,
      },
      {
        'title': 'Chứng Khoán',
        'icon': Icons.auto_graph,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Vietlott SMS',
        'icon': Icons.sms_outlined,
        'color': Colors.red,
      },
      {
        'title': 'Xem thêm\ndịch vụ',
        'icon': Icons.grid_view,
        'color': Colors.grey,
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemBuilder: (context, index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.transparent, // Nền trong suốt
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                services[index]['icon'],
                color: services[index]['color'],
                size: 32,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              services[index]['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        );
      },
    );
  }

  // Widget Banner Lắc Xì (Vẽ bằng code mô phỏng ảnh)
  Widget _buildEventBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF8A65), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Text nội dung
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  'Tích Lá Lộc càng nhiều\nThưởng cuối càng lớn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Đến 50 triệu',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          // Nút Chơi Ngay
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  'CHƠI NGAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget MoMo đề xuất
  Widget _buildRecommendedServices() {
    final List<Map<String, dynamic>> recommends = [
      {
        'title': 'Vay Nhanh',
        'icon': Icons.monetization_on_outlined,
        'color': Colors.orange,
      },
      {
        'title': 'Mua vé xem ...',
        'icon': Icons.local_movies_outlined,
        'color': Colors.orange,
      },
      {
        'title': 'Túi Thần Tài',
        'icon': Icons.shopping_bag_outlined,
        'color': Colors.red,
      },
      {
        'title': 'Ví Trả Sau',
        'icon': Icons.account_balance_wallet_outlined,
        'color': Colors.purple,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: recommends.map((item) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'], color: item['color'], size: 28),
            ),
            const SizedBox(height: 8),
            Text(item['title'], style: const TextStyle(fontSize: 11)),
          ],
        );
      }).toList(),
    );
  }

  // Widget Banner Gieo quẻ AI
  Widget _buildAIBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.yellow.shade200, Colors.yellow.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.red, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '2025 nhờ ai mà nở hoa?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Gieo quẻ với AI, tìm quý nhân của bạn',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Gieo ngay',
              style: TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Thanh điều hướng dưới cùng (Bottom Navigation)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.storefront, 'MoMo', color: Colors.pink),
                  _buildNavItem(Icons.card_giftcard, 'Ưu đãi', showDot: true),
                  const SizedBox(width: 50), // Khoảng trống cho nút QR ở giữa
                  _buildNavItem(Icons.history, 'Lịch sử GD'),
                  _buildNavItem(Icons.person_outline, 'Tôi'),
                ],
              ),
              // Nút Quét QR to ở giữa
              Positioned(
                top: -20,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Quét mọi QR',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label, {
    Color color = Colors.grey,
    bool showDot = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            Icon(icon, color: color, size: 24),
            if (showDot)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: color == Colors.pink
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
