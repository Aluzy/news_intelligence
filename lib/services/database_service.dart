// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/source.dart';
import '../models/article.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('news_intelligence.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Version incrémentée
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        logoUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sourceId TEXT NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        publishedAt TEXT NOT NULL,
        isAnalyzed INTEGER NOT NULL,
        summary TEXT,
        highlights TEXT,
        keywords TEXT,
        tone TEXT,
        fullContent TEXT,
        imageUrl TEXT,
        isPremium INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajouter les nouvelles colonnes si elles n'existent pas
      await db.execute('ALTER TABLE sources ADD COLUMN logoUrl TEXT');
      await db.execute('ALTER TABLE articles ADD COLUMN imageUrl TEXT');
      await db.execute('ALTER TABLE articles ADD COLUMN isPremium INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE articles ADD COLUMN isDeleted INTEGER DEFAULT 0');
    }
  }

  // Sources CRUD
  Future<int> createSource(NewsSource source) async {
    final db = await database;
    return await db.insert('sources', source.toMap());
  }

  Future<List<NewsSource>> getAllSources() async {
    final db = await database;
    final maps = await db.query('sources', orderBy: 'createdAt DESC');
    return maps.map((map) => NewsSource.fromMap(map)).toList();
  }

  Future<int> updateSource(NewsSource source) async {
    final db = await database;
    return await db.update(
      'sources',
      source.toMap(),
      where: 'id = ?',
      whereArgs: [source.id],
    );
  }

  Future<int> deleteSource(int id) async {
    final db = await database;
    return await db.delete('sources', where: 'id = ?', whereArgs: [id]);
  }

  // Articles CRUD
  Future<int> createArticle(Article article) async {
    final db = await database;
    try {
      return await db.insert('articles', article.toMap());
    } catch (e) {
      // Article déjà existant (URL unique)
      return 0;
    }
  }

  Future<List<Article>> getAllArticles() async {
    final db = await database;
    final maps = await db.query(
      'articles',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'publishedAt DESC',
      limit: 100,
    );
    return maps.map((map) => Article.fromMap(map)).toList();
  }

  Future<int> updateArticle(Article article) async {
    final db = await database;
    return await db.update(
      'articles',
      article.toMap(),
      where: 'id = ?',
      whereArgs: [article.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}