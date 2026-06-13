import 'package:flutter/material.dart';

import '../../../shared/widgets/section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置与设备说明')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SectionCard(
            title: '串口默认参数',
            subtitle: 'MVP 使用 115200 / 8N1。后续版本可扩展为每个会话单独配置。',
            child: Text('支持 Android USB OTG 与桌面 COM/tty 设备。常见芯片包括 CH340、FTDI、CP210x、CDC ACM。'),
          ),
          SizedBox(height: 20),
          SectionCard(
            title: '录制文件格式',
            subtitle: '手机与电脑端保持一致，便于直接复制和导入。',
            child: Text('每个会话目录包含 video.mp4、serial_log.csv、session_meta.json。'),
          ),
          SizedBox(height: 20),
          SectionCard(
            title: '平台注意事项',
            child: Text('Android 需要摄像头、麦克风与 USB Host 权限。桌面端需要摄像头权限以及系统串口驱动。Linux 可能需要将用户加入 dialout/uucp 等串口权限组。'),
          ),
        ],
      ),
    );
  }
}
