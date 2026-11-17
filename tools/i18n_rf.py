"""Generates entry/src/main/resources/<locale>/element/string.json for RFulash.

Base is English; zh_CN keeps the original Simplified Chinese wording.
Run from the project root: python3 tools/i18n_rf.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'entry/src/main/resources')

# key: (en, zh_CN, zh_Hant, ru_RU, ja_JP, ko_KR)
S = {
    'module_desc': (
        'Native Flash player for HarmonyOS powered by Ruffle',
        '基于 Ruffle 的鸿蒙原生 Flash 播放器',
        '基於 Ruffle 的鴻蒙原生 Flash 播放器',
        'Нативный Flash-плеер для HarmonyOS на основе Ruffle',
        'Ruffle を搭載した HarmonyOS ネイティブ Flash プレーヤー',
        'Ruffle 기반 HarmonyOS 네이티브 Flash 플레이어'),
    'EntryAbility_desc': ('RFulash', 'RFulash', 'RFulash', 'RFulash', 'RFulash', 'RFulash'),
    'EntryAbility_label': ('RFulash', 'RFulash', 'RFulash', 'RFulash', 'RFulash', 'RFulash'),
    'permission_download_reason': (
        'The library needs access to Downloads to store imported SWF files in Download/com.52wfun.rfulash/players',
        '播放库需要访问下载目录，用于在 下载/com.52wfun.rfulash/players 文件夹中存放导入的 SWF 文件',
        '播放庫需要存取下載目錄，用於在「下載/com.52wfun.rfulash/players」資料夾中存放匯入的 SWF 檔案',
        'Библиотеке нужен доступ к папке «Загрузки», чтобы хранить импортированные SWF-файлы в Download/com.52wfun.rfulash/players',
        'ライブラリがダウンロードディレクトリにアクセスし、インポートした SWF ファイルを Download/com.52wfun.rfulash/players に保存します',
        '라이브러리가 다운로드 폴더에 접근하여 가져온 SWF 파일을 Download/com.52wfun.rfulash/players에 저장합니다'),

    'app_tagline': (
        'Native Flash player for HarmonyOS',
        '鸿蒙原生 Flash 播放器',
        '鴻蒙原生 Flash 播放器',
        'Нативный Flash-плеер для HarmonyOS',
        'HarmonyOS ネイティブ Flash プレーヤー',
        'HarmonyOS 네이티브 Flash 플레이어'),
    'home_title': ('Home', '首页', '首頁', 'Главная', 'ホーム', '홈'),
    'tab_play': ('Play', '播放', '播放', 'Воспроизведение', '再生', '재생'),
    'about_title': ('About', '关于', '關於', 'О приложении', 'このアプリについて', '정보'),

    'status_initializing': (
        'Initializing renderer…', '正在初始化渲染器…', '正在初始化渲染器…',
        'Инициализация рендерера…', 'レンダラーを初期化しています…', '렌더러 초기화 중…'),
    'status_load_failed': (
        'Load failed', '加载失败', '載入失敗',
        'Ошибка загрузки', '読み込みに失敗しました', '로드 실패'),
    'status_loading': (
        'Loading…', '正在加载…', '正在載入…',
        'Загрузка…', '読み込み中…', '로딩 중…'),
    'status_ready': (
        'Ready. Select a SWF file to start playing',
        '就绪，选择一个 SWF 文件开始播放',
        '就緒，選擇一個 SWF 檔案開始播放',
        'Готово. Выберите SWF-файл, чтобы начать',
        '準備完了。SWF ファイルを選択して再生を開始',
        '준비 완료. SWF 파일을 선택하여 재생을 시작하세요'),
    'status_reloading': (
        'Reloading…', '正在重新加载…', '正在重新載入…',
        'Перезагрузка…', '再読み込み中…', '다시 로딩 중…'),
    'no_movie': (
        'No SWF open', '未打开 SWF', '未開啟 SWF',
        'SWF не открыт', 'SWF 未選択', '열린 SWF 없음'),

    'error_engine_init': (
        'Cannot initialize the Ruffle engine',
        '无法初始化 Ruffle 引擎',
        '無法初始化 Ruffle 引擎',
        'Не удалось инициализировать движок Ruffle',
        'Ruffle エンジンを初期化できません',
        'Ruffle 엔진을 초기화할 수 없습니다'),
    'error_refused_file': (
        'The native layer rejected this file',
        '原生层拒绝了这个文件',
        '原生層拒絕了這個檔案',
        'Нативный уровень отклонил этот файл',
        'ネイティブ層がこのファイルを拒否しました',
        '네이티브 계층이 이 파일을 거부했습니다'),
    'error_refused_url': (
        'The native layer rejected this link',
        '原生层拒绝了该链接',
        '原生層拒絕了該連結',
        'Нативный уровень отклонил эту ссылку',
        'ネイティブ層がこのリンクを拒否しました',
        '네이티브 계층이 이 링크를 거부했습니다'),
    'error_no_context': (
        'Cannot access the app context',
        '无法获取应用上下文',
        '無法取得應用程式內容',
        'Не удалось получить контекст приложения',
        'アプリのコンテキストを取得できません',
        '앱 컨텍스트를 가져올 수 없습니다'),
    'error_no_download_dir': (
        'Cannot access Downloads. Grant permission and try again',
        '无法访问下载目录，请授权后重试',
        '無法存取下載目錄，請授權後重試',
        'Нет доступа к папке «Загрузки». Разрешите доступ и повторите попытку',
        'ダウンロードディレクトリにアクセスできません。権限を許可して再試行してください',
        '다운로드 폴더에 접근할 수 없습니다. 권한을 허용한 후 다시 시도하세요'),

    'toast_movie_exited': (
        'Movie exited', '影片已退出', '影片已退出',
        'Фильм закрыт', 'ムービーを終了しました', '동영상이 종료되었습니다'),
    'toast_select_failed': (
        'Could not select the file: %s', '选择文件失败: %s', '選擇檔案失敗: %s',
        'Не удалось выбрать файл: %s', 'ファイルの選択に失敗しました: %s', '파일 선택 실패: %s'),
    'toast_save_failed': (
        'Could not save the file: %s', '保存文件失败: %s', '儲存檔案失敗: %s',
        'Не удалось сохранить файл: %s', 'ファイルの保存に失敗しました: %s', '파일 저장 실패: %s'),
    'toast_open_link_failed': (
        'Could not open the link: %s', '无法打开链接: %s', '無法開啟連結: %s',
        'Не удалось открыть ссылку: %s', 'リンクを開けません: %s', '링크를 열 수 없습니다: %s'),
    'toast_group_required': (
        'Enter a group name', '请输入分组名称', '請輸入分組名稱',
        'Введите имя группы', 'グループ名を入力してください', '그룹 이름을 입력하세요'),
    'toast_group_invalid': (
        'Invalid group name', '分组名称不合法', '分組名稱不合法',
        'Недопустимое имя группы', 'グループ名が無効です', '올바르지 않은 그룹 이름입니다'),
    'toast_group_exists': (
        'A group with this name already exists', '同名分组已存在', '同名分組已存在',
        'Группа с таким именем уже существует', '同名のグループが既に存在します', '같은 이름의 그룹이 이미 있습니다'),
    'toast_group_create_failed': (
        'Could not create the group: %s', '创建分组失败: %s', '建立分組失敗: %s',
        'Не удалось создать группу: %s', 'グループの作成に失敗しました: %s', '그룹 생성 실패: %s'),
    'toast_group_created': (
        'Group “%s” created', '已创建分组「%s」', '已建立分組「%s」',
        'Группа «%s» создана', 'グループ「%s」を作成しました', '그룹 "%s" 생성됨'),
    'toast_group_rename_failed': (
        'Rename failed: %s', '重命名失败: %s', '重新命名失敗: %s',
        'Не удалось переименовать: %s', '名前の変更に失敗しました: %s', '이름 변경 실패: %s'),
    'toast_group_renamed': (
        'Renamed to “%s”', '已重命名为「%s」', '已重新命名為「%s」',
        'Переименовано в «%s»', '「%s」に名前を変更しました', '"%s"(으)로 이름 변경됨'),
    'toast_move_exists': (
        'The target group already contains a file with this name',
        '目标分组里已有同名文件',
        '目標分組裡已有同名檔案',
        'В целевой группе уже есть файл с таким именем',
        '移動先のグループに同名のファイルがあります',
        '대상 그룹에 같은 이름의 파일이 이미 있습니다'),
    'toast_moved': (
        'Moved to “%s”', '已移动到「%s」', '已移動到「%s」',
        'Перемещено в «%s»', '「%s」に移動しました', '"%s"(으)로 이동됨'),
    'toast_move_failed': (
        'Move failed: %s', '移动失败: %s', '移動失敗: %s',
        'Не удалось переместить: %s', '移動に失敗しました: %s', '이동 실패: %s'),
    'toast_group_delete_failed': (
        'Could not delete the group: %s', '删除分组失败: %s', '刪除分組失敗: %s',
        'Не удалось удалить группу: %s', 'グループの削除に失敗しました: %s', '그룹 삭제 실패: %s'),
    'toast_group_deleted': (
        'Group deleted', '已删除分组', '已刪除分組',
        'Группа удалена', 'グループを削除しました', '그룹 삭제됨'),
    'toast_import_failed': (
        'Import failed: %s', '导入失败: %s', '匯入失敗: %s',
        'Не удалось импортировать: %s', 'インポートに失敗しました: %s', '가져오기 실패: %s'),
    'toast_import_permission': (
        'Downloads permission is required to import into the library',
        '需要下载目录权限才能导入播放库',
        '需要下載目錄權限才能匯入播放庫',
        'Для импорта в библиотеку нужен доступ к папке «Загрузки»',
        'ライブラリへのインポートにはダウンロードディレクトリの権限が必要です',
        '라이브러리로 가져오려면 다운로드 폴더 권한이 필요합니다'),
    'toast_import_added': (
        'Added %d file(s) to %s', '已添加 %d 个文件到%s', '已新增 %d 個檔案到%s',
        'Добавлено файлов: %d → %s', '%d 個のファイルを %s に追加しました', '파일 %d개를 %s에 추가했습니다'),
    'toast_import_failed_count': (
        'Import failed: %d file(s) could not be added',
        '导入失败：%d 个文件未能添加',
        '匯入失敗：%d 個檔案未能新增',
        'Импорт не удался: не удалось добавить файлов: %d',
        'インポート失敗：%d 個のファイルを追加できませんでした',
        '가져오기 실패: 파일 %d개를 추가하지 못했습니다'),
    'toast_import_partial': (
        'Added %d file(s), %d failed',
        '已添加 %d 个文件，%d 个失败',
        '已新增 %d 個檔案，%d 個失敗',
        'Добавлено файлов: %d, не удалось: %d',
        '%d 個のファイルを追加し、%d 個失敗しました',
        '파일 %d개 추가됨, %d개 실패'),
    'toast_library_removed': (
        'Removed from the library', '已从播放库移除', '已從播放庫移除',
        'Удалено из библиотеки', 'ライブラリから削除しました', '라이브러리에서 제거됨'),
    'toast_library_cleared': (
        'Library cleared', '已清空播放库', '已清空播放庫',
        'Библиотека очищена', 'ライブラリを空にしました', '라이브러리를 비웠습니다'),
    'toast_library_refreshed': (
        'Refreshed', '已刷新', '已重新整理',
        'Обновлено', '更新しました', '새로고침됨'),
    'toast_file_missing_import': (
        'The file is no longer accessible. Import it again',
        '文件已不可访问，请重新导入',
        '檔案已無法存取，請重新匯入',
        'Файл больше недоступен. Импортируйте его снова',
        'ファイルにアクセスできません。再度インポートしてください',
        '파일에 접근할 수 없습니다. 다시 가져오세요'),
    'toast_file_missing_open': (
        'The file is no longer accessible. Open it again',
        '文件已不可访问，请重新打开',
        '檔案已無法存取，請重新開啟',
        'Файл больше недоступен. Откройте его снова',
        'ファイルにアクセスできません。再度開いてください',
        '파일에 접근할 수 없습니다. 다시 여세요'),
    'toast_url_invalid': (
        'Enter a link starting with http:// or https://',
        '请输入 http:// 或 https:// 链接',
        '請輸入 http:// 或 https:// 連結',
        'Введите ссылку, начинающуюся с http:// или https://',
        'http:// または https:// で始まるリンクを入力してください',
        'http:// 또는 https://로 시작하는 링크를 입력하세요'),
    'toast_recent_removed': (
        'Removed from Recent', '已从最近打开移除', '已從最近開啟移除',
        'Удалено из недавних', '最近開いた項目から削除しました', '최근 항목에서 제거됨'),
    'toast_recents_cleared': (
        'Recent cleared', '已清空最近打开', '已清空最近開啟',
        'Недавние очищены', '最近開いた項目を空にしました', '최근 항목을 비웠습니다'),
    'toast_link_copied': (
        'Link copied', '链接已复制', '已複製連結',
        'Ссылка скопирована', 'リンクをコピーしました', '링크가 복사되었습니다'),
    'toast_license_read_failed': (
        'Could not read the license file', '读取许可文件失败', '讀取授權檔案失敗',
        'Не удалось прочитать файл лицензии', 'ライセンスファイルを読み込めません', '라이선스 파일을 읽지 못했습니다'),
    'toast_copied': (
        'Copied', '已复制', '已複製',
        'Скопировано', 'コピーしました', '복사됨'),
    'toast_copy_failed': (
        'Copy failed', '复制失败', '複製失敗',
        'Не удалось скопировать', 'コピーに失敗しました', '복사 실패'),

    'action_cancel': ('Cancel', '取消', '取消', 'Отмена', 'キャンセル', '취소'),
    'action_delete': ('Delete', '删除', '刪除', 'Удалить', '削除', '삭제'),
    'action_remove': ('Remove', '移除', '移除', 'Убрать', '削除', '제거'),
    'action_clear': ('Clear', '清空', '清空', 'Очистить', 'クリア', '비우기'),
    'action_confirm': ('OK', '确定', '確定', 'ОК', 'OK', '확인'),
    'action_create': ('Create', '创建', '建立', 'Создать', '作成', '만들기'),

    'dialog_delete_group': (
        'Delete group', '删除分组', '刪除分組',
        'Удалить группу', 'グループを削除', '그룹 삭제'),
    'dialog_delete_group_msg': (
        'Delete group “%s”? The %d movie file(s) in it will also be deleted.',
        '确定要删除分组「%s」吗？分组里的 %d 个作品文件也会一并删除。',
        '確定要刪除分組「%s」嗎？分組裡的 %d 個作品檔案也會一併刪除。',
        'Удалить группу «%s»? Все файлы фильмов в ней (%d) также будут удалены.',
        'グループ「%s」を削除しますか？グループ内の作品ファイル %d 個も一緒に削除されます。',
        '그룹 "%s"을(를) 삭제하시겠습니까? 그룹에 있는 작품 파일 %d개도 함께 삭제됩니다.'),
    'dialog_delete_empty_group_msg': (
        'Delete the empty group “%s”?',
        '确定要删除空分组「%s」吗？',
        '確定要刪除空分組「%s」嗎？',
        'Удалить пустую группу «%s»?',
        '空のグループ「%s」を削除しますか？',
        '빈 그룹 "%s"을(를) 삭제하시겠습니까?'),
    'dialog_remove_work': (
        'Remove movie', '移除作品', '移除作品',
        'Убрать фильм', '作品を削除', '작품 제거'),
    'dialog_remove_work_msg': (
        'Remove “%s” from the library? Its file will also be deleted.',
        '确定要从播放库中移除「%s」吗？对应文件也会一并删除。',
        '確定要從播放庫中移除「%s」嗎？對應檔案也會一併刪除。',
        'Убрать «%s» из библиотеки? Соответствующий файл также будет удалён.',
        '「%s」をライブラリから削除しますか？対応するファイルも一緒に削除されます。',
        '라이브러리에서 "%s"을(를) 제거하시겠습니까? 해당 파일도 함께 삭제됩니다.'),
    'dialog_clear_library': (
        'Clear library', '清空播放库', '清空播放庫',
        'Очистить библиотеку', 'ライブラリを空にする', '라이브러리 비우기'),
    'dialog_clear_library_msg': (
        'Clear the library? %d movie(s)%s will also be deleted.',
        '确定要清空播放库吗？%d 个作品%s会一并删除。',
        '確定要清空播放庫嗎？%d 個作品%s會一併刪除。',
        'Очистить библиотеку? Все фильмы (%d)%s также будут удалены.',
        'ライブラリを空にしますか？作品 %d 個%sも一緒に削除されます。',
        '라이브러리를 비우시겠습니까? 작품 %d개%s도 함께 삭제됩니다.'),
    'dialog_groups_suffix': (
        ' and %d group folder(s)', '和 %d 个分组文件夹', '和 %d 個分組資料夾',
        ' и папок групп: %d', ' とグループフォルダー %d 個', ' 및 그룹 폴더 %d개'),
    'dialog_remove_record': (
        'Remove entry', '移除记录', '移除記錄',
        'Убрать запись', '履歴を削除', '기록 제거'),
    'dialog_remove_record_msg': (
        'Remove “%s” from Recent?',
        '确定要从最近打开中移除「%s」吗？',
        '確定要從最近開啟中移除「%s」嗎？',
        'Убрать «%s» из недавних?',
        '「%s」を最近開いた項目から削除しますか？',
        '최근 항목에서 "%s"을(를) 제거하시겠습니까?'),
    'dialog_clear_recents': (
        'Clear Recent', '清空最近打开', '清空最近開啟',
        'Очистить недавние', '最近開いた項目を空にする', '최근 항목 비우기'),
    'dialog_clear_recents_msg': (
        'Clear all %d entries?',
        '确定要清空全部 %d 条记录吗？',
        '確定要清空全部 %d 條記錄嗎？',
        'Очистить все записи (%d)?',
        '履歴 %d 件をすべて削除しますか？',
        '기록 %d개를 모두 비우시겠습니까?'),

    'library_title': ('Library', '播放库', '播放庫', 'Библиотека', 'ライブラリ', '라이브러리'),
    'recents_title': ('Recent', '最近打开', '最近開啟', 'Недавние', '最近開いた項目', '최근 열기'),
    'lib_import': ('Import', '导入', '匯入', 'Импорт', 'インポート', '가져오기'),
    'lib_new_group': ('New group', '新建分组', '新增分組', 'Новая группа', '新規グループ', '새 그룹'),
    'lib_search': ('Search', '搜索', '搜尋', 'Поиск', '検索', '검색'),
    'lib_refresh': ('Refresh', '刷新', '重新整理', 'Обновить', '更新', '새로고침'),
    'lib_clear': ('Clear', '清空', '清空', 'Очистить', 'クリア', '비우기'),
    'search_placeholder': (
        'Search movies or groups', '搜索作品或分组', '搜尋作品或分組',
        'Поиск фильмов и групп', '作品やグループを検索', '작품 또는 그룹 검색'),
    'no_match': (
        'No matches', '无匹配结果', '無符合結果',
        'Ничего не найдено', '一致する項目がありません', '일치하는 결과 없음'),
    'no_works': (
        'No movies yet. Tap “New group” or “Import” to add some',
        '暂无作品，点击「新建分组」或「导入」添加',
        '暫無作品，點擊「新增分組」或「匯入」新增',
        'Пока нет фильмов. Нажмите «Новая группа» или «Импорт», чтобы добавить',
        '作品がありません。「新規グループ」または「インポート」から追加してください',
        '작품이 없습니다. "새 그룹" 또는 "가져오기"를 눌러 추가하세요'),
    'no_records': (
        'No entries', '暂无记录', '暫無記錄',
        'Пока нет записей', '履歴はありません', '기록 없음'),
    'group_default': ('Default', '默认', '預設', 'По умолчанию', 'デフォルト', '기본'),
    'group_quoted': ('“%s”', '「%s」', '「%s」', '«%s»', '「%s」', '"%s"'),
    'group_count': ('%d', '%d 个', '%d 個', '%d', '%d 個', '%d개'),
    'group_rename_note': (
        'Renaming also changes the folder name in players; the movies inside are kept.',
        '重命名会同步修改 players 里的文件夹名，里面的作品会保留。',
        '重新命名會同步修改 players 裡的資料夾名稱，裡面的作品會保留。',
        'При переименовании меняется имя папки в players, фильмы внутри сохраняются.',
        '名前を変更すると players 内のフォルダー名も変わりますが、中の作品は保持されます。',
        '이름을 변경하면 players의 폴더 이름도 함께 바뀌며, 안에 있는 작품은 유지됩니다.'),
    'group_create_note': (
        'A group is a same-named subfolder in players, visible and manageable in File Manager.',
        '分组就是 players 文件夹里的同名子文件夹，可以在文件管理器里直接查看和管理。',
        '分組就是 players 資料夾裡同名的子資料夾，可以在檔案管理員裡直接檢視和管理。',
        'Группа — это одноимённая подпапка в players; её можно просматривать и изменять в файловом менеджере.',
        'グループは players 内の同名サブフォルダーで、ファイルマネージャーから直接確認・管理できます。',
        '그룹은 players 폴더 안의 같은 이름 하위 폴더이며, 파일 관리자에서 직접 확인하고 관리할 수 있습니다.'),
    'group_name_placeholder': (
        'Group name', '分组名称', '分組名稱',
        'Имя группы', 'グループ名', '그룹 이름'),
    'move_prompt': (
        'Move “%s” to:', '将「%s」移动到：', '將「%s」移動到：',
        'Переместить «%s» в:', '「%s」の移動先：', '"%s" 이동 위치:'),
    'move_no_groups': (
        'No groups yet. Create one with “New group” in the library.',
        '还没有分组，先在播放库页点「新建分组」创建一个。',
        '還沒有分組，先在播放庫頁點「新增分組」建立一個。',
        'Групп пока нет. Создайте её кнопкой «Новая группа» в библиотеке.',
        'グループがありません。ライブラリで「新規グループ」を押して作成してください。',
        '아직 그룹이 없습니다. 라이브러리에서 "새 그룹"을 눌러 만드세요.'),
    'recent_link': ('Link', '链接', '連結', 'Ссылка', 'リンク', '링크'),
    'recent_local': ('Local', '本地', '本機', 'Локальный', 'ローカル', '로컬'),

    'ctx_delete': ('Delete', '删除', '刪除', 'Удалить', '削除', '삭제'),
    'ctx_import_to_group': (
        'Import to this group', '导入到此分组', '匯入到此分組',
        'Импорт в эту группу', 'このグループにインポート', '이 그룹으로 가져오기'),
    'ctx_rename': (
        'Rename', '重命名', '重新命名',
        'Переименовать', '名前を変更', '이름 변경'),
    'ctx_delete_group': (
        'Delete group', '删除分组', '刪除分組',
        'Удалить группу', 'グループを削除', '그룹 삭제'),
    'ctx_open': ('Open', '打开', '開啟', 'Открыть', '開く', '열기'),
    'ctx_move_to_group': (
        'Move to group', '移动到分组', '移動到分組',
        'Переместить в группу', 'グループに移動', '그룹으로 이동'),
    'ctx_remove_from_library': (
        'Remove from library', '从播放库移除', '從播放庫移除',
        'Убрать из библиотеки', 'ライブラリから削除', '라이브러리에서 제거'),

    'menu_open_swf': (
        'Open SWF', '打开 SWF', '開啟 SWF',
        'Открыть SWF', 'SWF を開く', 'SWF 열기'),
    'menu_library': ('Library', '播放库', '播放庫', 'Библиотека', 'ライブラリ', '라이브러리'),
    'menu_recents': ('Recent', '最近打开', '最近開啟', 'Недавние', '最近開いた項目', '최근 열기'),
    'menu_pause': ('Pause', '暂停', '暫停', 'Пауза', '一時停止', '일시정지'),
    'menu_resume': ('Resume', '继续', '繼續', 'Продолжить', '再開', '계속'),
    'menu_settings': ('Settings', '设置', '設定', 'Настройки', '設定', '설정'),
    'menu_fullscreen': ('Fullscreen', '全屏', '全螢幕', 'Полный экран', '全画面', '전체 화면'),

    'home_select_hint': (
        'Select a SWF file to start playing',
        '选择一个 SWF 文件开始播放',
        '選擇一個 SWF 檔案開始播放',
        'Выберите SWF-файл, чтобы начать',
        'SWF ファイルを選択して再生を開始',
        'SWF 파일을 선택하여 재생을 시작하세요'),
    'home_auto_collect': (
        'The library automatically collects files in Download/RFulash/players',
        '播放库会自动收录 下载/RFulash/players 里的文件',
        '播放庫會自動收錄「下載/RFulash/players」裡的檔案',
        'Библиотека автоматически собирает файлы из Download/RFulash/players',
        'ライブラリは Download/RFulash/players 内のファイルを自動で収録します',
        '라이브러리는 Download/RFulash/players의 파일을 자동으로 수집합니다'),
    'home_steps_title': (
        'Three steps to play', '三步开始播放', '三步開始播放',
        'Три шага к воспроизведению', '3 ステップで再生', '3단계로 재생 시작'),
    'home_step1_title': ('Open SWF', '打开 SWF', '開啟 SWF', 'Открыть SWF', 'SWF を開く', 'SWF 열기'),
    'home_step1_desc': (
        'Pick a local SWF file and start playing immediately',
        '选择本地 SWF 文件，立即开始播放',
        '選擇本機 SWF 檔案，立即開始播放',
        'Выберите локальный SWF-файл и сразу начинайте воспроизведение',
        'ローカルの SWF ファイルを選ぶとすぐに再生できます',
        '로컬 SWF 파일을 선택하면 바로 재생됩니다'),
    'home_step2_title': ('Library', '播放库', '播放庫', 'Библиотека', 'ライブラリ', '라이브러리'),
    'home_step2_desc': (
        'Automatically collects files in Download/RFulash/players',
        '自动收录 下载/RFulash/players 里的文件',
        '自動收錄「下載/RFulash/players」裡的檔案',
        'Автоматически собирает файлы из Download/RFulash/players',
        'Download/RFulash/players 内のファイルを自動で収録します',
        'Download/RFulash/players의 파일을 자동으로 수집합니다'),
    'home_step3_title': (
        'Immersive playback', '沉浸播放', '沉浸播放',
        'Иммерсивное воспроизведение', '没入感のある再生', '몰입형 재생'),
    'home_step3_desc': (
        'Fullscreen, scaling and keyboard/mouse control included',
        '全屏、画面缩放与键鼠操作一应俱全',
        '全螢幕、畫面縮放與鍵鼠操作一應俱全',
        'Полный экран, масштабирование и управление клавиатурой и мышью',
        '全画面、拡大縮小、キーボード・マウス操作をすべて搭載',
        '전체 화면, 화면 확대/축소, 키보드·마우스 조작까지 지원'),
    'home_privacy': (
        'All files are parsed locally and never uploaded',
        '所有文件均在本机解析，不上传网络',
        '所有檔案均在本機解析，不上傳網路',
        'Все файлы обрабатываются локально и никуда не отправляются',
        'すべてのファイルは端末内で処理され、ネットワークに送信されません',
        '모든 파일은 기기에서 처리되며 네트워크로 전송되지 않습니다'),
    'home_hero_desc': (
        'Powered by the native Ruffle engine, no browser needed. Pick a local SWF file and get the full Flash experience.',
        '原生 Ruffle 引擎驱动，无需浏览器。选择本地 SWF 文件，即可获得完整的 Flash 播放体验。',
        '原生 Ruffle 引擎驅動，無需瀏覽器。選擇本機 SWF 檔案，即可獲得完整的 Flash 播放體驗。',
        'Работает на нативном движке Ruffle — браузер не нужен. Выберите локальный SWF-файл и получите полноценное воспроизведение Flash.',
        'ネイティブ Ruffle エンジン搭載でブラウザ不要。ローカルの SWF ファイルを選ぶだけで、Flash をそのまま再生できます。',
        '네이티브 Ruffle 엔진 기반으로 브라우저가 필요 없습니다. 로컬 SWF 파일을 선택하면 Flash를 그대로 재생할 수 있습니다.'),
    'a11y_open_swf_file': (
        'Open SWF file', '打开 SWF 文件', '開啟 SWF 檔案',
        'Открыть SWF-файл', 'SWF ファイルを開く', 'SWF 파일 열기'),
    'keyboard_placeholder': (
        'Enter text…', '输入文本…', '輸入文字…',
        'Введите текст…', 'テキストを入力…', '텍스트 입력…'),
    'picker_file': ('File', '文件', '檔案', 'Файл', 'ファイル', '파일'),
    'picker_flash': (
        'Flash movie', 'Flash 动画', 'Flash 動畫',
        'Flash-анимация', 'Flash アニメーション', 'Flash 애니메이션'),

    'player_settings_title': (
        'Player settings', '播放器设置', '播放器設定',
        'Настройки плеера', 'プレーヤー設定', '플레이어 설정'),
    'settings_basic_group': (
        'Basics & core', '基本与核心', '基本與核心',
        'Основные настройки', '基本とコア', '기본 및 핵심'),
    'settings_look_group': (
        'Appearance', '外观风格', '外觀風格',
        'Внешний вид', '外観スタイル', '모양 스타일'),
    'row_play_settings': (
        'Playback', '播放设置', '播放設定',
        'Воспроизведение', '再生設定', '재생 설정'),
    'row_sound_settings': ('Sound', '声音设置', '聲音設定', 'Звук', 'サウンド', '소리'),
    'row_picture_settings': ('Picture', '画面设置', '畫面設定', 'Изображение', '映像', '화면'),
    'row_display_settings': ('Display', '显示设置', '顯示設定', 'Экран', '表示', '디스플레이'),
    'row_appearance_settings': ('Appearance', '外观设置', '外觀設定', 'Оформление', '外観', '모양'),
    'row_theme_settings': ('Theme', '主题设置', '主題設定', 'Тема', 'テーマ', '테마'),
    'row_glow': (
        'Immersive material', '沉浸光感', '沉浸光感',
        'Иммерсивный материал', 'イマーシブマテリアル', '이머시브 머티리얼'),
    'row_language_settings': ('Language', '语言设置', '語言設定', 'Язык', '言語', '언어'),
    'row_about': (
        'About RFulash', '关于 RFulash', '關於 RFulash',
        'О приложении RFulash', 'RFulash について', 'RFulash 정보'),
    'player_reload': ('Reload', '重新加载', '重新載入', 'Перезагрузить', '再読み込み', '다시 로드'),
    'player_step_forward': (
        'Step forward', '单步前进', '單步前進',
        'Шаг вперёд', '1 フレーム進む', '한 단계 앞으로'),
    'player_master_volume': ('Volume', '主音量', '主音量', 'Громкость', '音量', '볼륨'),
    'player_force_scale': (
        'Force scale mode', '强制缩放模式', '強制縮放模式',
        'Принудительный режим масштаба', 'スケールモードを強制', '배율 모드 강제'),
    'player_letterbox': (
        'Show black bars (letterbox)', '显示黑边（信箱模式）', '顯示黑邊（信箱模式）',
        'Показывать чёрные полосы (letterbox)', '黒帯を表示（レターボックス）', '검은 여백 표시(레터박스)'),
    'player_enter_fullscreen': (
        'Enter fullscreen', '进入全屏', '進入全螢幕',
        'Полноэкранный режим', '全画面にする', '전체 화면 시작'),
    'player_exit_fullscreen': (
        'Exit fullscreen', '退出全屏', '退出全螢幕',
        'Выйти из полноэкранного режима', '全画面を終了', '전체 화면 종료'),
    'a11y_back_player_settings': (
        'Back to player settings', '返回 播放器设置', '返回播放器設定',
        'Назад к настройкам плеера', 'プレーヤー設定に戻る', '플레이어 설정으로 돌아가기'),

    'quality_low': ('Low', '低', '低', 'Низкое', '低', '낮음'),
    'quality_medium': ('Medium', '中', '中', 'Среднее', '中', '중간'),
    'quality_high': ('High', '高', '高', 'Высокое', '高', '높음'),
    'quality_best': ('Best', '最佳', '最佳', 'Наилучшее', '最高', '최고'),

    'scale_fit_window': (
        'Fit to window', '适应窗口', '適應視窗',
        'По размеру окна', 'ウィンドウに合わせる', '창에 맞춤'),
    'scale_exact_fit': (
        'Exact fit', '精确适配', '精確適配',
        'Точная подгонка', '正確に合わせる', '정확히 맞춤'),
    'scale_fill_crop': (
        'Fill and crop', '铺满裁切', '鋪滿裁切',
        'Заполнить с обрезкой', '全体を埋めて切り抜き', '채우고 자르기'),
    'scale_original': (
        'Original size', '原始大小', '原始大小',
        'Исходный размер', '元のサイズ', '원본 크기'),

    'theme_follow_system': (
        'Follow system', '跟随系统', '跟隨系統',
        'Как в системе', 'システムに従う', '시스템 설정 따르기'),
    'theme_light': ('Light', '浅色', '淺色', 'Светлая', 'ライト', '라이트'),
    'theme_dark': ('Dark', '深色', '深色', 'Тёмная', 'ダーク', '다크'),

    'accent_orange': ('Orange', '橙色', '橘色', 'Оранжевый', 'オレンジ', '주황'),
    'accent_blue': ('Blue', '蓝色', '藍色', 'Синий', 'ブルー', '파랑'),
    'accent_purple': ('Purple', '紫色', '紫色', 'Фиолетовый', 'パープル', '보라'),
    'accent_red': ('Red', '红色', '紅色', 'Красный', 'レッド', '빨강'),
    'accent_teal': ('Teal', '青绿色', '青綠色', 'Бирюзовый', 'ティール', '청록'),

    'glow_soft': ('Soft', '柔和', '柔和', 'Мягкий', 'ソフト', '부드럽게'),
    'glow_standard': ('Standard', '标准', '標準', 'Стандартный', '標準', '표준'),
    'glow_clear': ('Clear', '通透', '通透', 'Прозрачный', 'クリア', '투명'),
    'glow_hint_soft': (
        'Thicker material, calmer background, easier to read in bright light',
        '材质更厚重，背景更安静，强光下更易读',
        '材質更厚重，背景更安靜，強光下更易讀',
        'Более плотный материал, спокойный фон, лучше читается при ярком свете',
        '素材感が強く背景が落ち着き、明るい場所でも読みやすくなります',
        '소재가 더 두껍고 배경이 차분해져 밝은 곳에서도 읽기 쉽습니다'),
    'glow_hint_standard': (
        'Balanced transparency and legibility, the system default',
        '通透度与可读性平衡，系统默认档位',
        '通透度與可讀性平衡，系統預設檔位',
        'Баланс прозрачности и читаемости, системное значение по умолчанию',
        '透過性と読みやすさのバランスが取れたシステム既定の設定',
        '투명도와 가독성의 균형을 맞춘 시스템 기본 설정'),
    'glow_hint_clear': (
        'Thinnest material, background shows through the most',
        '材质最薄，背景内容透出最多',
        '材質最薄，背景內容透出最多',
        'Самый тонкий материал, фон просвечивает сильнее всего',
        '素材が最も薄く、背景が最も透けて見えます',
        '소재가 가장 얇아 배경이 가장 많이 비칩니다'),
    'glow_note_supported': (
        'Adjusts the material thickness of the floating tab bar and half-modal panels. Changes apply immediately and are saved on this device.',
        '调整悬浮底栏和半模态面板的材质厚薄，修改后立即生效并保存在本机。',
        '調整懸浮底欄和半模態面板的材質厚薄，修改後立即生效並保存在本機。',
        'Настраивает плотность материала плавающей панели вкладок и полумодальных панелей. Изменения применяются сразу и сохраняются на устройстве.',
        'フローティングタブバーとハーフモーダルパネルのマテリアルの厚みを調整します。変更はすぐに反映され、本機に保存されます。',
        '플로팅 탭 바와 하프 모달 패널의 소재 두께를 조정합니다. 변경 사항은 즉시 적용되고 이 기기에 저장됩니다.'),
    'glow_note_unsupported': (
        'This device does not support system immersive material. The setting is saved and will apply on supported devices.',
        '当前设备不支持系统沉浸光感，设置会保存并在支持的设备上生效。',
        '當前裝置不支援系統沉浸光感，設定會儲存並在支援的裝置上生效。',
        'Это устройство не поддерживает системный иммерсивный материал. Настройка сохранена и применится на поддерживаемых устройствах.',
        'このデバイスはシステムのイマーシブマテリアルに対応していません。設定は保存され、対応デバイスで反映されます。',
        '이 기기는 시스템 이머시브 머티리얼을 지원하지 않습니다. 설정은 저장되며 지원되는 기기에서 적용됩니다.'),

    'about_version': ('Version', '版本', '版本', 'Версия', 'バージョン', '버전'),
    'about_developer': ('Developer', '开发者', '開發者', 'Разработчик', '開発者', '개발자'),
    'about_package': ('Bundle name', '包名', '套件名稱', 'Имя пакета', 'パッケージ名', '패키지 이름'),
    'about_website': ('Website', '官网', '官網', 'Сайт', '公式サイト', '공식 웹사이트'),
    'about_email': ('Email', '联系邮箱', '聯絡信箱', 'Почта', '連絡先メール', '이메일'),
    'about_licenses': (
        'Open-source licenses', '开源许可', '開放原始碼授權',
        'Лицензии с открытым кодом', 'オープンソースライセンス', '오픈소스 라이선스'),

    'licenses_list_title': (
        'Licenses', '许可列表', '授權列表',
        'Список лицензий', 'ライセンス一覧', '라이선스 목록'),
    'licenses_section_projects': (
        'Project names and repositories', '项目名称与地址', '專案名稱與網址',
        'Названия проектов и репозитории', 'プロジェクト名とリポジトリ', '프로젝트 이름 및 저장소'),
    'licenses_section_third': (
        'Third-party components and licenses', '第三方组件与许可', '第三方元件與授權',
        'Сторонние компоненты и лицензии', 'サードパーティコンポーネントとライセンス', '서드파티 구성 요소 및 라이선스'),
    'licenses_section_mit_sub': (
        "One of Ruffle's dual licenses (MIT or Apache-2.0, at your option)",
        'Ruffle 双许可之一（MIT 或 Apache-2.0 任选）',
        'Ruffle 雙授權之一（MIT 或 Apache-2.0 任選）',
        'Одна из двух лицензий Ruffle (MIT или Apache-2.0 на выбор)',
        'Ruffle のデュアルライセンスのひとつ（MIT または Apache-2.0 を選択可能）',
        'Ruffle 듀얼 라이선스 중 하나(MIT 또는 Apache-2.0 선택)'),
    'licenses_section_apache_sub': (
        "The other option of Ruffle's dual license",
        'Ruffle 双许可的另一选项',
        'Ruffle 雙授權的另一選項',
        'Другая лицензия Ruffle на выбор',
        'Ruffle のデュアルライセンスのもう一方',
        'Ruffle 듀얼 라이선스의 다른 옵션'),
    'licenses_section_third_sub': (
        'Third-party libraries used by Ruffle, with full license texts',
        'Ruffle 依赖的第三方库清单与许可全文',
        'Ruffle 相依的第三方函式庫清單與授權全文',
        'Сторонние библиотеки Ruffle и полные тексты лицензий',
        'Ruffle が依存するサードパーティライブラリの一覧とライセンス全文',
        'Ruffle이 사용하는 서드파티 라이브러리 목록과 전체 라이선스'),
    'licenses_this_project': (
        'This project', '本项目', '本專案',
        'Этот проект', '本プロジェクト', '이 프로젝트'),
    'licenses_upstream_project': (
        'Upstream project', '上游项目', '上游專案',
        'Upstream-проект', '上流プロジェクト', '업스트림 프로젝트'),
    'licenses_components': (
        'Component and version', '组件与版本', '元件與版本',
        'Компонент и версия', 'コンポーネントとバージョン', '구성 요소 및 버전'),
    'licenses_copyright': (
        'Copyright notice', '版权声明', '版權聲明',
        'Уведомление об авторских правах', '著作権表示', '저작권 고지'),
    'licenses_full_text': (
        'Full license text', '许可全文', '授權全文',
        'Полный текст лицензии', 'ライセンス全文', '전체 라이선스'),
    'licenses_note_label': ('Notice', '说明', '說明', 'Примечание', '説明', '안내'),
    'licenses_note_body': (
        "The upstream LICENSE.md lists Ruffle's third-party components and their full license texts; that file ships with this app. Components compiled into this app's engine but not listed separately upstream are covered by the supplemental notice.",
        '上游 LICENSE.md 已列出 Ruffle 的第三方组件清单与许可全文，该文件随应用一并分发。未被上游清单单列、但已编译进本应用引擎的组件，见补充声明。',
        '上游 LICENSE.md 已列出 Ruffle 的第三方元件清單與授權全文，該檔案隨應用程式一併散布。未被上游清單單列、但已編譯進本應用程式引擎的元件，請見補充聲明。',
        'В LICENSE.md из upstream-репозитория перечислены сторонние компоненты Ruffle и полные тексты лицензий; этот файл поставляется вместе с приложением. Компоненты, скомпилированные в движок приложения, но не указанные в upstream-списке отдельно, описаны в дополнительном уведомлении.',
        '上流の LICENSE.md には Ruffle のサードパーティコンポーネント一覧とライセンス全文が掲載されており、このファイルはアプリに同梱されています。上流の一覧に個別記載がないものの、本アプリのエンジンに組み込まれたコンポーネントは補足声明に記載しています。',
        '업스트림 LICENSE.md에는 Ruffle의 서드파티 구성 요소 목록과 전체 라이선스가 포함되어 있으며, 이 파일은 앱과 함께 배포됩니다. 업스트림 목록에 개별 표기되지 않았지만 본 앱 엔진에 포함된 구성 요소는 보충 고지에 정리되어 있습니다.'),
    'licenses_view_upstream': (
        'View the full upstream LICENSE.md',
        '查看上游 LICENSE.md 全文',
        '檢視上游 LICENSE.md 全文',
        'Открыть полный LICENSE.md из upstream',
        '上流の LICENSE.md 全文を表示',
        '업스트림 LICENSE.md 전체 보기'),
    'licenses_view_supplement': (
        'View the full supplemental notice',
        '查看补充声明全文',
        '檢視補充聲明全文',
        'Открыть полное дополнительное уведомление',
        '補足声明の全文を表示',
        '보충 고지 전체 보기'),
    'licenses_supplement_title': (
        'Third-party supplemental notice',
        '第三方组件补充声明',
        '第三方元件補充聲明',
        'Дополнительное уведомление о сторонних компонентах',
        'サードパーティ補足声明',
        '서드파티 보충 고지'),
    'licenses_supplement_sub': (
        'Components not listed separately upstream, with licenses',
        '上游清单未单列的组件与许可',
        '上游清單未單列的元件與授權',
        'Компоненты, не указанные отдельно в upstream, и их лицензии',
        '上流の一覧に個別記載のないコンポーネントとライセンス',
        '업스트림 목록에 개별 표기되지 않은 구성 요소 및 라이선스'),
    'licenses_upstream_sub': (
        'License file bundled with the upstream repository',
        '上游仓库随附的许可文件原文',
        '上游倉庫隨附的授權檔案原文',
        'Файл лицензии, поставляемый с upstream-репозиторием',
        '上流リポジトリに同梱されたライセンスファイルの原文',
        '업스트림 저장소에 포함된 라이선스 파일 원문'),
    'a11y_licenses_back': (
        'Back to licenses', '返回 开源许可列表', '返回授權列表',
        'Назад к списку лицензий', 'ライセンス一覧に戻る', '라이선스 목록으로 돌아가기'),
    'a11y_about_back': (
        'Back to About RFulash', '返回 关于 RFulash', '返回關於 RFulash',
        'Назад к «О приложении RFulash»', 'RFulash についてに戻る', 'RFulash 정보로 돌아가기'),
    'ruffle_components': (
        'Ruffle %s (ruffle_core, ruffle_render_gles and other crates)',
        'Ruffle %s（ruffle_core、ruffle_render_gles 等 crates）',
        'Ruffle %s（ruffle_core、ruffle_render_gles 等 crates）',
        'Ruffle %s (crates ruffle_core, ruffle_render_gles и др.)',
        'Ruffle %s（ruffle_core、ruffle_render_gles などの crate）',
        'Ruffle %s(ruffle_core, ruffle_render_gles 등 크레이트)'),

    'language_settings_title': (
        'Language', '语言设置', '語言設定', 'Язык', '言語', '언어'),
    'language_system': (
        'Follow system', '跟随系统', '跟隨系統',
        'Как в системе', 'システムに従う', '시스템 설정 따르기'),
    # Language names always stay in their own language.
    'language_zh': ('简体中文', '简体中文', '简体中文', '简体中文', '简体中文', '简体中文'),
    'language_zh_hant': ('繁體中文', '繁體中文', '繁體中文', '繁體中文', '繁體中文', '繁體中文'),
    'language_ru': ('Русский', 'Русский', 'Русский', 'Русский', 'Русский', 'Русский'),
    'language_en': ('English', 'English', 'English', 'English', 'English', 'English'),
    'language_ja': ('日本語', '日本語', '日本語', '日本語', '日本語', '日本語'),
    'language_ko': ('한국어', '한국어', '한국어', '한국어', '한국어', '한국어'),

    'untitled_swf': ('Untitled SWF', '未命名 SWF', '未命名 SWF', 'Без имени', '名称未設定', '이름 없음'),
}

LOCALES = ['base', 'zh_CN', 'zh_Hant', 'ru_RU', 'ja_JP', 'ko_KR']
INDEX = {'base': 0, 'zh_CN': 1, 'zh_Hant': 2, 'ru_RU': 3, 'ja_JP': 4, 'ko_KR': 5}


def main() -> None:
    for locale in LOCALES:
        entries = []
        for key, values in S.items():
            entries.append({'name': key, 'value': values[INDEX[locale]]})
        directory = os.path.join(RES, locale, 'element')
        os.makedirs(directory, exist_ok=True)
        path = os.path.join(directory, 'string.json')
        with open(path, 'w', encoding='utf-8') as handle:
            json.dump({'string': entries}, handle, ensure_ascii=False, indent=2)
            handle.write('\n')
    print('wrote %d keys x %d locales' % (len(S), len(LOCALES)))


if __name__ == '__main__':
    main()
