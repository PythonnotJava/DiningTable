import 'package:diningtable/Compose/renew_pwd.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'random_avatar.dart';

class Myself extends StatefulWidget {
  const Myself({super.key});
  @override
  State<StatefulWidget> createState() => MyselfState();
}

class MyselfState extends State<Myself> {
  late int seed;
  late String style;

  @override
  void initState() {
    seed = DateTime.now().millisecondsSinceEpoch;
    style = randomStyle();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.purple.shade300,
                            Colors.pink.shade200,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
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
                                ),
                              ],
                            ),
                            child: InkWell(
                              child: ClipOval(child: RandomAvatar(seed: seed, style: style,)),
                              onTap: () => setState(() {
                                seed = DateTime.now().millisecondsSinceEpoch;
                                style = randomStyle();
                              }),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),

                // 修改密码
                ListTile(
                  leading: Icon(Icons.lock_outline, color: Colors.purple),
                  title: Text("修改密码"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => showChangePasswordDialog(context)
                ),

                SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "DiningTable v1.0.0",
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
    );
  }
}
