import 'package:flutter/material.dart';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '〇✕ゲーム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const TicTacToeGame(),
    );
  }
}

enum GameMode { pvp, vsCpu }

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> _board = List.filled(9, '');
  bool _isOTurn = true;
  String _winner = '';
  List<int> _winningLine = [];
  GameMode _mode = GameMode.pvp;

  int _oWins = 0;
  int _xWins = 0;
  int _draws = 0;

  static const List<List<int>> _winningCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // 横
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // 縦
    [0, 4, 8], [2, 4, 6]             // 斜め
  ];

  void _resetBoard() {
    setState(() {
      _board = List.filled(9, '');
      _isOTurn = true;
      _winner = '';
      _winningLine = [];
    });
  }

  void _resetScores() {
    _resetBoard();
    setState(() {
      _oWins = 0;
      _xWins = 0;
      _draws = 0;
    });
  }

  void _onCellTapped(int index) {
    if (_board[index] != '' || _winner != '') return;

    setState(() {
      _board[index] = _isOTurn ? '〇' : '✕';
      _isOTurn = !_isOTurn;
    });

    _checkWinner();

    if (_mode == GameMode.vsCpu && _winner == '' && !_isOTurn) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _makeCpuMove();
        }
      });
    }
  }

  void _makeCpuMove() {
    if (_winner != '' || !_board.contains('')) return;

    int bestMove = -1;

    // 1. CPU (✕) の勝利手をチェック
    for (int i = 0; i < 9; i++) {
      if (_board[i] == '') {
        _board[i] = '✕';
        if (_checkSimulatedWin('✕')) {
          bestMove = i;
          _board[i] = '';
          break;
        }
        _board[i] = '';
      }
    }

    // 2. プレイヤー (〇) のリーチをブロック
    if (bestMove == -1) {
      for (int i = 0; i < 9; i++) {
        if (_board[i] == '') {
          _board[i] = '〇';
          if (_checkSimulatedWin('〇')) {
            bestMove = i;
            _board[i] = '';
            break;
          }
          _board[i] = '';
        }
      }
    }

    // 3. 中央を狙う
    if (bestMove == -1 && _board[4] == '') {
      bestMove = 4;
    }

    // 4. 四隅を狙う
    if (bestMove == -1) {
      List<int> corners = [0, 2, 6, 8]..shuffle();
      for (int corner in corners) {
        if (_board[corner] == '') {
          bestMove = corner;
          break;
        }
      }
    }

    // 5. 空いているマスを選ぶ
    if (bestMove == -1) {
      List<int> emptyIndices = [];
      for (int i = 0; i < 9; i++) {
        if (_board[i] == '') emptyIndices.add(i);
      }
      if (emptyIndices.isNotEmpty) {
        emptyIndices.shuffle();
        bestMove = emptyIndices.first;
      }
    }

    if (bestMove != -1) {
      setState(() {
        _board[bestMove] = '✕';
        _isOTurn = true;
      });
      _checkWinner();
    }
  }

  bool _checkSimulatedWin(String symbol) {
    for (var combo in _winningCombos) {
      if (_board[combo[0]] == symbol &&
          _board[combo[1]] == symbol &&
          _board[combo[2]] == symbol) {
        return true;
      }
    }
    return false;
  }

  void _checkWinner() {
    for (var combo in _winningCombos) {
      if (_board[combo[0]] != '' &&
          _board[combo[0]] == _board[combo[1]] &&
          _board[combo[0]] == _board[combo[2]]) {
        setState(() {
          _winner = _board[combo[0]];
          _winningLine = combo;
          if (_winner == '〇') {
            _oWins++;
          } else {
            _xWins++;
          }
        });
        return;
      }
    }

    if (!_board.contains('') && _winner == '') {
      setState(() {
        _winner = 'Draw';
        _draws++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('〇✕ゲーム'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'スコアリセット',
            onPressed: _resetScores,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // モード切替
              SegmentedButton<GameMode>(
                segments: const [
                  ButtonSegment<GameMode>(
                    value: GameMode.pvp,
                    label: Text('2人対戦'),
                    icon: Icon(Icons.people),
                  ),
                  ButtonSegment<GameMode>(
                    value: GameMode.vsCpu,
                    label: Text('VS CPU'),
                    icon: Icon(Icons.smart_toy),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (Set<GameMode> newSelection) {
                  setState(() {
                    _mode = newSelection.first;
                    _resetScores();
                  });
                },
              ),
              const SizedBox(height: 16),

              // スコアボード
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScoreCard(
                    title: 'プレイヤー 〇',
                    score: _oWins,
                    color: Colors.blue.shade700,
                    isActive: _winner == '' && _isOTurn,
                  ),
                  _ScoreCard(
                    title: '引き分け',
                    score: _draws,
                    color: Colors.grey.shade600,
                    isActive: false,
                  ),
                  _ScoreCard(
                    title: _mode == GameMode.pvp ? 'プレイヤー ✕' : 'CPU ✕',
                    score: _xWins,
                    color: Colors.red.shade700,
                    isActive: _winner == '' && !_isOTurn,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ステータス表示
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _winner != ''
                      ? (_winner == 'Draw'
                          ? Colors.orange.withValues(alpha: 0.2)
                          : (_winner == '〇'
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2)))
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getGameStatusText(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _winner == '〇'
                        ? Colors.blue.shade700
                        : (_winner == '✕'
                            ? Colors.red.shade700
                            : (_winner == 'Draw'
                                ? Colors.orange.shade800
                                : colorScheme.onSurface)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ゲーム盤 (3x3 Grid)
              Center(
                child: Container(
                  width: 320,
                  height: 320,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final isWinningCell = _winningLine.contains(index);
                      final cellText = _board[index];

                      return GestureDetector(
                        onTap: () => _onCellTapped(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isWinningCell
                                ? Colors.amber.shade300
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              cellText,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: cellText == '〇'
                                    ? Colors.blue.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // リセットボタン
              ElevatedButton.icon(
                onPressed: _resetBoard,
                icon: const Icon(Icons.replay),
                label: const Text('次のゲームを開始'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGameStatusText() {
    if (_winner == '〇') {
      return '〇 の勝ちです！ 🎉';
    } else if (_winner == '✕') {
      return _mode == GameMode.vsCpu ? 'CPU の勝ちです！ 🤖' : '✕ の勝ちです！ 🎉';
    } else if (_winner == 'Draw') {
      return '引き分けです！ 🤝';
    } else {
      if (_mode == GameMode.vsCpu && !_isOTurn) {
        return 'CPU思考中... 🤖';
      }
      return '${_isOTurn ? "〇" : "✕"} のターンです';
    }
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final bool isActive;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
