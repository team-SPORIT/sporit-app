import 'package:flutter/foundation.dart';

import '../models/profile.dart';

// 로그인한 사용자의 프로필을 앱 전체에서 공유한다. 상단바의 프로필 사진처럼
// 마이페이지 밖에서도 같은 값을 보여줘야 하는 곳이 있어서, 프로필을 새로 받거나
// 수정할 때마다 여기에 넣어두고 필요한 화면이 구독한다.
//
// 로그인 직후 /auth/sync 응답으로 채워지고, 아직 모르는 동안에는 null이다.
class ProfileController extends ValueNotifier<Profile?> {
  ProfileController._() : super(null);

  static final ProfileController instance = ProfileController._();
}
