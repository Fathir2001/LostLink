import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../post/data/repositories/post_repository.dart';
import '../../../post/domain/models/post.dart';

/// Selected post type filter (null = all)
final selectedPostTypeProvider = StateProvider<PostType?>((ref) => null);

/// Home posts state notifier
class HomePostsNotifier extends StateNotifier<AsyncValue<PaginatedPosts>> {
  final Ref _ref;
  PostFilters _currentFilters = const PostFilters();

  HomePostsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadPosts();
  }

  PostRepository get _repository => _ref.read(postRepositoryProvider);

  Future<void> loadPosts() async {
    state = const AsyncValue.loading();
    try {
      final selectedType = _ref.read(selectedPostTypeProvider);
      _currentFilters = PostFilters(type: selectedType);
      final result = await _repository.getPosts(_currentFilters);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final selectedType = _ref.read(selectedPostTypeProvider);
      _currentFilters = PostFilters(type: selectedType);
      final result = await _repository.getPosts(_currentFilters);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore) return;

    try {
      _currentFilters = _currentFilters.copyWith(page: currentState.page + 1);
      final result = await _repository.getPosts(_currentFilters);
      
      state = AsyncValue.data(PaginatedPosts(
        posts: [...currentState.posts, ...result.posts],
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
      ));
    } catch (e, st) {
      // Keep current state on pagination error
    }
  }
}

/// Home posts provider
final homePostsProvider =
    StateNotifierProvider<HomePostsNotifier, AsyncValue<PaginatedPosts>>((ref) {
  return HomePostsNotifier(ref);
});
