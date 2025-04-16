import raylib;
import raylib.raylib_types;

import std.stdio;
import std.random : uniform;
import std.datetime : MonoTime, Duration;
import core.time : Duration, msecs;

enum int[4][4][7] tetrominoShapes = [
    // I
    [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // J
    [
        [1, 0, 0, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // L
    [
        [0, 0, 1, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // O
    [
        [1, 1, 0, 0],
        [1, 1, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // S
    [
        [0, 1, 1, 0],
        [1, 1, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // T
    [
        [0, 1, 0, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    // Z
    [
        [1, 1, 0, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ]
];

enum BOARD_WIDTH = 10;
enum BOARD_HEIGHT = 20;
enum TILE_SIZE = 30;

int[BOARD_WIDTH][BOARD_HEIGHT] board; // Note the order of dimensions: [height][width]
int[4][4] currentBlock;
int blockX = 3, blockY = 0;
int currentBlockIndex;

void spawnBlock() {
    currentBlockIndex = uniform(0, 7);
    currentBlock = tetrominoShapes[currentBlockIndex];
    blockX = 3;
    blockY = 0;
}

bool checkCollision() {
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            int drawX = blockX + x;
            int drawY = blockY + y;
            if (currentBlock[y][x] == 1) {
                // Boundary check to ensure the block stays inside the grid
                if (drawX < 0 || drawX >= BOARD_WIDTH || drawY >= BOARD_HEIGHT || board[drawY][drawX] != 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

void fixBlock() {
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            int drawX = blockX + x;
            int drawY = blockY + y;
            if (currentBlock[y][x] == 1) {
                if (drawX >= 0 && drawX < BOARD_WIDTH && drawY >= 0 && drawY < BOARD_HEIGHT) {
                    board[drawY][drawX] = 1;
                }
            }
        }
    }
    clearFullLines();  // ラインをクリア
}

int getLeftmostX(ref int[4][4] block) {
    int minX = 4;
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            if (block[y][x] == 1 && x < minX) {
                minX = x;
            }
        }
    }
    return minX;
}

int getRightmostX(ref int[4][4] block) {
    int maxX = -1;
    foreach (y; 0 .. 4) {
        foreach (x; 0 .. 4) {
            if (block[y][x] == 1 && x > maxX) {
                maxX = x;
            }
        }
    }
    return maxX;
}

void adjustBlockPosition() {
    int left = getLeftmostX(currentBlock);
    int right = getRightmostX(currentBlock);

    // 左端が画面外 or 衝突してたら右にずらす
    while (blockX + left < 0 || checkCollision(currentBlock)) {
        blockX++;
        if (checkCollision(currentBlock)) {
            blockX--; // ずらしても解決しなかったら戻してbreak
            break;
        }
        left = getLeftmostX(currentBlock);
    }

    // 右端が画面外 or 衝突してたら左にずらす
    while (blockX + right >= BOARD_WIDTH || checkCollision(currentBlock)) {
        blockX--;
        if (checkCollision(currentBlock)) {
            blockX++; // ずらしても解決しなかったら戻してbreak
            break;
        }
        right = getRightmostX(currentBlock);
    }
}

void drawBlock() {
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            int drawX = blockX + x;
            int drawY = blockY + y;
            if (currentBlock[y][x] == 1 && drawX >= 0 && drawX < BOARD_WIDTH && drawY >= 0 && drawY < BOARD_HEIGHT) {
                DrawRectangle(drawX * TILE_SIZE, drawY * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1, Colors.MAROON);
            }
        }
    }
}

void rotateBlock() {
    int[4][4] rotatedBlock;
    foreach (y; 0 .. 4)
        foreach (x; 0 .. 4)
            rotatedBlock[x][3 - y] = currentBlock[y][x];

    if (!checkCollision(rotatedBlock)) {
        currentBlock = rotatedBlock;
    } else {
		tryWallKick(rotatedBlock);
	}
}

void tryWallKick(int[4][4] rotatedBlock) {
    // 試しに左に1マスずらしてチェック
    blockX -= 1;
    if (!checkCollision(rotatedBlock)) {
        currentBlock = rotatedBlock;
        return;
    }

    // 左にずらしてダメだったら元に戻して、右に1マスずらす
    blockX += 2;
    if (!checkCollision(rotatedBlock)) {
        currentBlock = rotatedBlock;
        return;
    }

    // それでもダメなら元の位置に戻して何もしない
    blockX -= 1;
}


bool checkCollision(int[4][4] block) {
    // 回転したブロックで衝突をチェック
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            int drawX = blockX + x;
            int drawY = blockY + y;
            if (block[y][x] == 1) {
                // ボードの範囲外か、すでにブロックがある場合は衝突
                if (drawX < 0 || drawX >= BOARD_WIDTH || drawY >= BOARD_HEIGHT || board[drawY][drawX] != 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

void hardDrop() {
    while (!checkCollision()) {
        blockY++;
    }
    blockY--;           // 衝突したから1マス戻す
    fixBlock();         // 盤面に固定
    spawnBlock();       // 次のブロック
}

void clearFullLines() {
    // ラインが揃っているかチェックして、揃っている場合は削除
    for (int y = BOARD_HEIGHT - 1; y >= 0; y--) {
        bool isFullLine = true;
        // 各行をチェック
        for (int x = 0; x < BOARD_WIDTH; x++) {
            if (board[y][x] == 0) {
                isFullLine = false;
                break;
            }
        }

        // 揃っている行を削除して、上の行を1つ下にずらす
        if (isFullLine) {
            // 行を下にシフト
            for (int shiftY = y; shiftY > 0; shiftY--) {
                for (int x = 0; x < BOARD_WIDTH; x++) {
                    board[shiftY][x] = board[shiftY - 1][x];
                }
            }
            // 最上行をクリア
            for (int x = 0; x < BOARD_WIDTH; x++) {
                board[0][x] = 0;
            }
            y++;  // 1行削除したので、再度同じyをチェックする
        }
    }
}

void main() {
    InitWindow(BOARD_WIDTH * TILE_SIZE, BOARD_HEIGHT * TILE_SIZE, "D テトリス");

    SetTargetFPS(60);
    spawnBlock();

    MonoTime lastDrop = MonoTime.currTime;
    Duration dropInterval = 500.msecs;

    while (!WindowShouldClose()) {
        // 入力処理
        if (IsKeyPressed(KeyboardKey.KEY_LEFT))  	blockX--;
        if (IsKeyPressed(KeyboardKey.KEY_RIGHT)) 	blockX++;
        if (IsKeyPressed(KeyboardKey.KEY_DOWN))  	hardDrop();
		if (IsKeyPressed(KeyboardKey.KEY_Z)) 		rotateBlock();  // 回転処理

        adjustBlockPosition();  // テトミノの位置補正

        // 自動で下に落ちる処理
        if (MonoTime.currTime - lastDrop > dropInterval) {
            blockY++;
            if (checkCollision()) {
                blockY--; // Revert the block's position
                fixBlock(); // Fix the block to the board
                spawnBlock(); // Spawn a new block
            }
            lastDrop = MonoTime.currTime;
        }

        BeginDrawing();
        ClearBackground(Colors.RAYWHITE);

        // 盤面の描画
        for (int y = 0; y < BOARD_HEIGHT; y++) {
            for (int x = 0; x < BOARD_WIDTH; x++) {
                if (board[y][x] != 0) {
                    DrawRectangle(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE - 1, TILE_SIZE - 1, Colors.DARKGRAY);
                }
            }
        }

        // ブロックの描画
        drawBlock();

        EndDrawing();
    }

    CloseWindow();
}
