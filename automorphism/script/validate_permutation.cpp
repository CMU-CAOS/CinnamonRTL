#include <iostream>
#include <sstream>
#include <vector>
#include <string>
#include <set>
#include <unordered_map>
#include <algorithm>

std::string print(const std::vector<int>& data) {
	std::stringstream ss;
	for (auto v : data) {
		ss << v << ",";
	}
	return ss.str();
}

int main() {
	const int n = 4, level = 2;
	const int hn = n / 2;

	std::unordered_map<std::string, std::pair<int, int>> valid;
	for (int mask1 = 0;mask1 < (1 << (level * hn));mask1++) {
		for (int mask2 = 0;mask2 < (1 << (level * hn));mask2++) {
			std::vector<int> data(n);

			// Initialize data
			for (int i = 0;i < n;i++) data[i] = i;

			// Mask1
			for (int d = 0;d < level;d++) {
				int bs = (1 << (level - d));
				int hbs = bs / 2;
				for (int blk = 0;blk < n;blk += bs) {
					for (int i = 0;i < hbs;i++) {
						int pos = d * hn + (blk / 2 + i);
						if (mask1 & (1 << pos)) {
							std::swap(data[blk + i], data[blk + i + hbs]);
						}
					}
				}
			}

			// Mask2
			for (int d = 0;d < level;d++) {
				int bs = (1 << (d + 1));
				int hbs = bs / 2;
				for (int blk = 0;blk < n;blk += bs) {
					for (int i = 0;i < hbs;i++) {
						int pos = d * hn + (blk / 2 + i);
						if (mask2 & (1 << pos)) {
							std::swap(data[blk + i], data[blk + i + hbs]);
						}
					}
				}
			}

			std::string res = print(data);
			valid[res] = std::make_pair(mask1, mask2);
		}
	}

	const std::string str = "1,0,2,3,";
	if (valid.count(str)) {
		auto p = valid[str];
		std::cout << p.first << " " << p.second << std::endl;
	}


	// Test permutation
	std::vector<int> perm(n);
	for (int i = 0;i < n;i++) perm[i] = i;
	do {
		std::string cur = print(perm);
		if (!valid.count(cur)) {
			std::cout << "Non-existent: " << cur << std::endl;;
		}
	} while (std::next_permutation(perm.begin(), perm.end()));


	return 0;
}
