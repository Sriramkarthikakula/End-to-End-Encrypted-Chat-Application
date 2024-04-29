import 'dart:math';

class HillCipher {
  final List<List<int>> _keyMatrix;
  final int _blockSize;

  HillCipher(this._keyMatrix) : _blockSize = _keyMatrix.length;

  String encrypt(String plaintext) {
    final List<int> plaintextNumbers = _convertToNumbers(plaintext);
    final List<int> encryptedNumbers = [];
    final List<int> spaceIndices = [];

    for (int i = 0; i < plaintextNumbers.length; i++) {
      if (plaintext[i] == ' ') {
        spaceIndices.add(i);
      }
    }

    for (int i = 0; i < plaintextNumbers.length; i += _blockSize) {
      final List<int> chunk = plaintextNumbers.sublist(
          i, min(i + _blockSize, plaintextNumbers.length));

      final List<int> result = _multiplyMatrix(chunk, _keyMatrix);

      encryptedNumbers.addAll(result);
    }

    String encrypted_text = _convertToString(encryptedNumbers);

    // Insert spaces into the encrypted text based on spaceIndices
    for (int index in spaceIndices) {
      encrypted_text = encrypted_text.substring(0, index) + ' ' + encrypted_text.substring(index);
    }

    return encrypted_text;
  }




  String decrypt(String ciphertext) {
    final List<int> spaceIndices = [];
    String modifiedCiphertext = ""; // Modified ciphertext without spaces

    for (int i = 0; i < ciphertext.length; i++) {
      if (ciphertext[i] == ' ') {
        spaceIndices.add(i);
      } else {
        modifiedCiphertext += ciphertext[i];
      }
    }

    final List<int> ciphertextNumbers = _convertToNumbers(modifiedCiphertext);
    final List<int> decryptedNumbers = [];
    final List<List<int>> inverseMatrix = _inverseMatrix(_keyMatrix);

    for (int i = 0; i < ciphertextNumbers.length; i += _blockSize) {
      final List<int> chunk = ciphertextNumbers.sublist(i, min(i + _blockSize, ciphertextNumbers.length));
      final List<int> result = _multiplyMatrix(chunk, inverseMatrix);
      decryptedNumbers.addAll(result);
    }

    String decryptedText = _convertToString(decryptedNumbers, preserveSpaces: true);
    List<String> decryptedText_list = decryptedText.split('');
    for(int i=0;i<decryptedText_list.length;i++){
      if(spaceIndices.contains(i)){
        decryptedText_list[i]=' ';
      }
    }
    decryptedText = decryptedText_list.join('');
    return decryptedText;
  }




  List<int> _convertToNumbers(String text) {
    return text.codeUnits.map((int codeUnit) {
      if (codeUnit == ' '.codeUnitAt(0)) {
        // Special code for space character
        return -2; // Use -2 as delimiter for space
      } else {
        return codeUnit - 'a'.codeUnitAt(0);
      }
    }).toList();
  }

  String _convertToString(List<int> numbers, {bool preserveSpaces = false}) {
    return numbers.map((int number) {
      if (number == -2) {
        // Special handling for delimiter
        return preserveSpaces ? ' ' : '';
      } else {
        return String.fromCharCode(number + 'a'.codeUnitAt(0));
      }
    }).join('');
  }


  List<int> _multiplyMatrix(List<int> chunk, List<List<int>> matrix) {
    final List<int> result = [];
    for (int i = 0; i < matrix.length; i++) {
      int sum = 0;
      for (int j = 0; j < matrix[i].length; j++) {
        if (chunk[j] != -2) { // Skip spaces in chunk
          sum += matrix[i][j] * chunk[j];
        }
      }
      result.add(sum % 26); // Ensure result is within the range of alphabet
    }
    return result;
  }

  List<List<int>> _inverseMatrix(List<List<int>> matrix) {
    final int det = matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0];
    final int detInverse = _modInverse(det, 26);

    final int a = matrix[0][0];
    final int b = matrix[0][1];
    final int c = matrix[1][0];
    final int d = matrix[1][1];

    final List<List<int>> inverseMatrix = [
      [(d * detInverse) % 26, (-b * detInverse) % 26],
      [(-c * detInverse) % 26, (a * detInverse) % 26],
    ];

    return inverseMatrix;
  }

  int _modInverse(int a, int m) {
    for (int i = 1; i < m; i++) {
      if ((a * i) % m == 1) {
        return i;
      }
    }
    return -1;
  }
}
