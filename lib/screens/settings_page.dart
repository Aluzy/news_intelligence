// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedApi = 'gemini';
  String _apiKey = '';
  int _articlesPerSource = 10;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedApi = prefs.getString('selected_api') ?? 'gemini';
      _apiKey = prefs.getString('${_selectedApi}_api_key') ?? '';
      _articlesPerSource = prefs.getInt('articles_per_source') ?? 10;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_api', _selectedApi);
    await prefs.setString('${_selectedApi}_api_key', _apiKey);
    await prefs.setInt('articles_per_source', _articlesPerSource);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres sauvegardés')),
      );
      Navigator.pop(context, true); // Retourner true pour indiquer des changements
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section API
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.api, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'API d\'analyse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Choisir le service :'),
                  const SizedBox(height: 8),
                  
                  // Radio Gemini
                  RadioListTile<String>(
                    title: const Text('Google Gemini'),
                    subtitle: const Text('Gratuit - 1500 req/jour'),
                    value: 'gemini',
                    groupValue: _selectedApi,
                    onChanged: (value) async {
                      setState(() => _selectedApi = value!);
                      final prefs = await SharedPreferences.getInstance();
                      _apiKey = prefs.getString('gemini_api_key') ?? '';
                    },
                  ),
                  
                  // Radio Claude
                  RadioListTile<String>(
                    title: const Text('Anthropic Claude'),
                    subtitle: const Text('Payant - Très performant'),
                    value: 'claude',
                    groupValue: _selectedApi,
                    onChanged: (value) async {
                      setState(() => _selectedApi = value!);
                      final prefs = await SharedPreferences.getInstance();
                      _apiKey = prefs.getString('claude_api_key') ?? '';
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Champ clé API
                  TextField(
                    controller: TextEditingController(text: _apiKey)
                      ..selection = TextSelection.collapsed(offset: _apiKey.length),
                    decoration: InputDecoration(
                      labelText: 'Clé API ${_selectedApi == "gemini" ? "Gemini" : "Claude"}',
                      hintText: _selectedApi == "gemini" ? 'AIza...' : 'sk-ant-...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () => _showApiHelp(),
                      ),
                    ),
                    obscureText: true,
                    onChanged: (value) => _apiKey = value,
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    _selectedApi == 'gemini'
                        ? 'Obtenez une clé sur: aistudio.google.com/app/apikey'
                        : 'Obtenez une clé sur: console.anthropic.com',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section Nombre d'articles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.numbers, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Chargement des articles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Articles par source : $_articlesPerSource',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _articlesPerSource.toDouble(),
                    min: 3,
                    max: 30,
                    divisions: 27,
                    label: _articlesPerSource.toString(),
                    onChanged: (value) {
                      setState(() => _articlesPerSource = value.round());
                    },
                  ),
                  Text(
                    'Plus le nombre est élevé, plus le chargement sera long',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bouton Sauvegarder
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Sauvegarder les paramètres'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showApiHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comment obtenir une clé ${_selectedApi == "gemini" ? "Gemini" : "Claude"} ?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _selectedApi == 'gemini'
                ? [
                    const Text('1. Allez sur aistudio.google.com/app/apikey'),
                    const SizedBox(height: 8),
                    const Text('2. Connectez-vous avec votre compte Google'),
                    const SizedBox(height: 8),
                    const Text('3. Cliquez sur "Create API Key"'),
                    const SizedBox(height: 8),
                    const Text('4. Copiez la clé (commence par AIza...)'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.green[50],
                      child: const Text(
                        '✓ Gratuit\n✓ 1500 requêtes/jour\n✓ Pas de carte bancaire',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                : [
                    const Text('1. Allez sur console.anthropic.com'),
                    const SizedBox(height: 8),
                    const Text('2. Créez un compte'),
                    const SizedBox(height: 8),
                    const Text('3. Allez dans "API Keys"'),
                    const SizedBox(height: 8),
                    const Text('4. Créez une clé (commence par sk-ant-...)'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.orange[50],
                      child: const Text(
                        '⚠ Payant\n✓ Très performant\n✓ ~0.01€ par article',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}