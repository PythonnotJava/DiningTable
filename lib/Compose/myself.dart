// file: compose/myself.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math';

class Myself extends StatelessWidget {
  const Myself({super.key});

  // 随机头像：每次冷启动都不一样，热重载也变（你也可以改成 SharedPreferences 存种子）
  String get randomAvatar {
    final seed = DateTime.now().millisecondsSinceEpoch ~/ 86400000 + // 每天换一次
        DateTime.now().hashCode; // 热重载也换
    final styles = ['adventurer', 'avataaars', 'big-ears', 'croodles', 'micah', 'open-peeps', 'personas'];
    final style = styles[Random(seed).nextInt(styles.length)];
    return 'https://api.dicebear.com/7.x/$style/svg?seed=$seed&size=180&backgroundColor=ffdfbf,ffd5dc,d1d4f9,c0aede,b6e3f4)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimationLimiter(
        child: CustomScrollView(
          slivers: [
            // 顶部大头像区
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景渐变
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [Colors.grey[900]!, Colors.black]
                              : [Colors.purple.shade300, Colors.pink.shade200],
                        ),
                      ),
                    ),
                    // 毛玻璃 + 头像
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: randomAvatar,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.grey[300]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "每日随机头像",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "点我可以换一个哦",
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 设置列表
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),

                // 修改密码
                ListTile(
                  leading: Icon(Icons.lock_outline, color: Colors.purple),
                  title: Text("修改密码"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 跳转修改密码页
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("开发中…")),
                    );
                  },
                ),

                // 主题设置（可展开）
                ExpansionTile(
                  leading: Icon(Icons.palette_outlined, color: Colors.orange),
                  title: Text("主题设置"),
                  childrenPadding: EdgeInsets.only(left: 72, right: 16, bottom: 8),
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text("跟随系统"),
                      value: ThemeMode.system,
                      groupValue: Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.dark // 你可以改成真正的全局状态
                          : ThemeMode.light,
                      onChanged: (v) {},
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text("白天模式"),
                      value: ThemeMode.light,
                      groupValue: Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      onChanged: (v) {},
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text("暗夜模式"),
                      value: ThemeMode.dark,
                      groupValue: Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      onChanged: (v) {},
                    ),
                  ],
                ),

                // 展开设置（可展开）
                ExpansionTile(
                  leading: Icon(Icons.open_in_full, color: Colors.blue),
                  title: Text("展开设置"),
                  childrenPadding: EdgeInsets.only(left: 72, right: 16, bottom: 8),
                  children: [
                    SwitchListTile(
                      title: Text("卡片点击后全屏展开"),
                      subtitle: Text("关闭则使用底部弹出式"),
                      value: true, // 你可以用 Provider/GetX 存真实状态
                      onChanged: (v) {},
                    ),
                    SwitchListTile(
                      title: Text("卡片跳转使用 Hero 动画"),
                      value: true,
                      onChanged: (v) {},
                    ),
                    ListTile(
                      title: Text("清除全部卡片"),
                      leading: Icon(Icons.delete_sweep, color: Colors.red),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("确认清空？"),
                            content: Text("此操作不可撤销"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text("取消")),
                              TextButton(
                                onPressed: () {
                                  // TODO: cardsBox.clear();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("已清空")),
                                  );
                                },
                                child: Text("确定", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // 20 高度空隙
                SizedBox(height: 20),

                // 版本号 & 版权
                Center(
                  child: Column(
                    children: [
                      Text(
                        "DiningTable v1.3.0",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      Text(
                        "© 2025 随便写写吧",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),

      // 点头像换一个（彩蛋）
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Icon(Icons.refresh, color: Colors.white),
        onPressed: () => (context as Element).markNeedsBuild(), // 强制刷新头像
      ),
    );
  }
}