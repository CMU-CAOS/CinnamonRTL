#include <iostream>
#include <vector>
#include <deque>
#include <cstdlib>


int find(std::vector<int>& p, int x) {
	if (p[x] == x) return x;
	return p[x] = find(p, p[x]);
}

void dfs(std::vector<int>& color, const std::vector<std::vector<int>>& req,
		int u, int c) {
	color[u] = c;
	for (auto v : req[u]) {
		if (color[v] == 0) {
			dfs(color, req, v, 3 - c);
		} else if (color[v] != 3 - c) {
			std::cerr << "Coloring failed" << std::endl;
			exit(1);
		}
	}
}

std::vector<bool> solveConflict(const std::vector<int>& vec) {
	int size = vec.size();
	int half = size / 2;

	std::vector<int> rev(size, 0);
	for (int i = 0;i < size;i++) rev[vec[i]] = i;

	std::vector<std::pair<int,  int>> same, different;
	for (int i = 0;i < half;i++) {
		int a = rev[i], b = rev[i + half];
		if (a / half == b / half) {
			// a and b different swap state
			different.push_back({a % half, b % half});
		} else {
			// a and b same swap state
			same.push_back({a % half, b % half});
		}
	}

	// Merge same swap
	std::vector<int> parent(half, 0);
	for (int i = 0;i < half;i++) parent[i] = i;
	for (auto [a, b] : same) {
		int x = find(parent, a), y = find(parent, b);
		parent[x] = y;
	}

	// Color different swap
	std::vector<std::vector<int>> req(half, std::vector<int>{});
	for (auto [a, b] : different) {
		int x = find(parent, a), y = find(parent, b);
		req[x].push_back(y);
		req[y].push_back(x);
	}
	std::vector<int> color(half, 0);
	for (int i = 0;i < half;i++) {
		if (color[i] == 0) {
			dfs(color, req, i, 1);
		}
	}

	// Return swap state
	std::vector<bool> ans;
	for (int i = 0;i < half;i++) {
		int x = find(parent, i);
		ans.push_back(color[x] == 2);
	}
	return ans;
}

std::deque<std::vector<bool>> solve(std::vector<int> perm) {
	int size = perm.size();
	int half = size / 2;

	if (size == 2) {
		std::vector<bool> left{perm[0] >= perm[1]};
		std::vector<bool> right{false};
		return std::deque<std::vector<bool>>{left, right};
	}

	// Apply left swap
	auto left = solveConflict(perm);
	for (int i = 0;i < half;i++) {
		if (left[i]) {
			std::swap(perm[i], perm[i + half]);
		}
	}

	// Create subtask
	std::vector<int> topPerm, bottomPerm;
	for (int i = 0;i < half;i++) topPerm.push_back(perm[i] % half);
	for (int i = half;i < size;i++) bottomPerm.push_back(perm[i] % half);

	auto topAns = solve(topPerm);
	auto bottomAns = solve(bottomPerm);
	int width = topAns.size();
	for (int i = 0;i < width;i++) {
		topAns[i].insert(topAns[i].end(),
			bottomAns[i].begin(), bottomAns[i].end()
		);
	}

	// Right swap
	std::vector<bool> right(half, false);
	for (int i = 0;i < half;i++) {
		int v = perm[i];
		right[v % half] = v < half ? 0 : 1;
	}


	topAns.push_front(left);
	topAns.push_back(right);
	return topAns;
}

int main() {
	const int size = 8, level = 3, half = 4;
	std::vector<int> perm{6, 2, 3, 1, 0, 4, 5, 7};

	auto ans = solve(perm);
	int value = 0;
	for (int i = 0;i < 2 * level;i++) {
		for (int j = 0;j < half;j++) {
			if (ans[i][j]) {
				value |= (1 << (i * half + j));
			}
		}
	}
	std::cout << value << std::endl;

	return 0;
}
