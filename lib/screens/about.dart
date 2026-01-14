import 'package:fluent_ui/fluent_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  final VoidCallback onBack;
  const AboutScreen({super.key, required this.onBack});

  Future<PackageInfo> _getInfo() => PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _getInfo(),
      builder: (context, snapshot) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Creator',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2B2B2B)
                      : const Color(0xFFFBFBFB),
                    border: Border.all(
                    color: FluentTheme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1d1d1d)
                      : const Color(0xFFe5e5e5),
                    width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage('assets/photos/liubquanti.png'),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'liubquanti',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'UI/UX and coding',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                          children: [
                          FilledButton(
                            child: SvgPicture.string('''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-brand-telegram"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 10l-4 4l6 6l4 -16l-18 7l4 2l2 6l3 -4" /></svg>''',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              FluentTheme.of(context).brightness == Brightness.light
                                ? const Color(0xFFffffff)
                                : const Color(0xFF1b1b1b),
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {launchUrl(Uri.parse('https://t.me/liubquanti'));},
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          child: SvgPicture.string('''<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="1.3"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-brand-instagram"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 8a4 4 0 0 1 4 -4h8a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-8a4 4 0 0 1 -4 -4z" /><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /><path d="M16.5 7.5v.01" /></svg>''',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              FluentTheme.of(context).brightness == Brightness.light
                                ? const Color(0xFFffffff)
                                : const Color(0xFF1b1b1b),
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {launchUrl(Uri.parse('https://instagram.com/liubquanti'));},
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          child: SvgPicture.string('''<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="1.3"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-brand-figma"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M6 3m0 3a3 3 0 0 1 3 -3h6a3 3 0 0 1 3 3v0a3 3 0 0 1 -3 3h-6a3 3 0 0 1 -3 -3z" /><path d="M9 9a3 3 0 0 0 0 6h3m-3 0a3 3 0 1 0 3 3v-15" /></svg>''',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              FluentTheme.of(context).brightness == Brightness.light
                                ? const Color(0xFFffffff)
                                : const Color(0xFF1b1b1b),
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {launchUrl(Uri.parse('https://www.figma.com/@liubquanti'));},
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          child: SvgPicture.string('''<svg  xmlns="http://www.w3.org/2000/svg"  width="24"  height="24"  viewBox="0 0 24 24"  fill="none"  stroke="currentColor"  stroke-width="1.3"  stroke-linecap="round"  stroke-linejoin="round"  class="icon icon-tabler icons-tabler-outline icon-tabler-brand-github"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 19c-4.3 1.4 -4.3 -2.5 -6 -3m12 5v-3.5c0 -1 .1 -1.4 -.5 -2c2.8 -.3 5.5 -1.4 5.5 -6a4.6 4.6 0 0 0 -1.3 -3.2a4.2 4.2 0 0 0 -.1 -3.2s-1.1 -.3 -3.5 1.3a12.3 12.3 0 0 0 -6.2 0c-2.4 -1.6 -3.5 -1.3 -3.5 -1.3a4.2 4.2 0 0 0 -.1 3.2a4.6 4.6 0 0 0 -1.3 3.2c0 4.6 2.7 5.7 5.5 6c-.6 .6 -.6 1.2 -.5 2v3.5" /></svg>''',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              FluentTheme.of(context).brightness == Brightness.light
                                ? const Color(0xFFffffff)
                                : const Color(0xFF1b1b1b),
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {launchUrl(Uri.parse('https://github.com/liubquanti'));},
                        ),
                      ],
                    )
                  ],
                )
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'API',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2B2B2B)
                    : const Color(0xFFFBFBFB),
                  border: Border.all(
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1d1d1d)
                    : const Color(0xFFe5e5e5),
                  width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage('assets/photos/libreview.png'),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LibreView API',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Glucose monitoring API',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This is community-driven, unofficial documentation for the LibreView API.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 10),
                    Row(
                        children: [
                        FilledButton(
                          child: const Icon(FluentSystemIcons.ic_fluent_globe_regular, size: 20),
                          onPressed: () {launchUrl(Uri.parse('https://libreview-unofficial.stoplight.io/'));},
                        ),
                      ],
                    )
                  ],
                )
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Support app',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2B2B2B)
                    : const Color(0xFFFBFBFB),
                  border: Border.all(
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1d1d1d)
                    : const Color(0xFFe5e5e5),
                  width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 31,
                      child: Button(
                        onPressed: () {
                          launchUrl(Uri.parse('https://apps.microsoft.com/detail/9N7DPSS8QMVF'));
                        },
                        child: const Text('Leave a review'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 31,
                      child: Button(
                        onPressed: () {
                          launchUrl(Uri.parse('https://github.com/liubquanti/Libre-Link-Up-Tray'));
                        },
                        child: const Text('Give a star'),
                      ),
                    ),
                  ],
                )
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'App info',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2B2B2B)
                    : const Color(0xFFFBFBFB),
                  border: Border.all(
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1d1d1d)
                    : const Color(0xFFe5e5e5),
                  width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Version',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                        Text(
                          snapshot.hasData ? snapshot.data!.version : 'Loading...',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Build',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                        Text(
                          snapshot.hasData ? snapshot.data!.buildNumber : 'Loading...',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Package',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                        Text(
                          snapshot.hasData ? snapshot.data!.packageName : 'Loading...',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Installer',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                        Text(
                          snapshot.hasData ? (snapshot.data!.installerStore ?? 'Unknown') : 'Loading...',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ],
                )
              ),
              const SizedBox(height: 26),
            ],
          ),
          ),
        );
      },
    );
  }
}