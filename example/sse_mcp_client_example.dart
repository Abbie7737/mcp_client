import 'dart:async'; // Added for Future.delayed and potentially other async operations
import 'dart:convert'; // Added for jsonEncode if needed for tool calls
import 'dart:io';
// import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:mcp_client/mcp_client.dart';

// Logger for this example - can be kept or replaced entirely by debugPrint
final Logger _logger = Logger.getLogger('sse_mcp_client_example');

/// Example MCP client application that connects to an SSE-based MCP server.
/// This client demonstrates how to establish an SSE connection,
/// handle events, and interact with the server.
void main() async {
  // Configure logger level if still used alongside debugPrint
  _logger.setLevel(LogLevel.debug);

  // Optional: Create a log file for persistent output, supplementing debugPrint
  final logFile = File('sse_mcp_client_example.log');
  IOSink? logSink = logFile.openWrite(); // Make logSink nullable

  _log('Starting SSE MCP client example...', logSink);
  print('[SSE Client] Starting SSE MCP client example...');

  // Create an MCP client instance
  // The client's name and version are for identification purposes.
  // Capabilities define what features the client supports.
  final client = McpClient.createClient( // Use type inference; McpClient.createClient() likely returns a 'Client' type
    name: 'Example SSE MCP Client',
    version: '1.0.1', // Incremented version for the new example
    capabilities: ClientCapabilities(
      roots: true, // Indicates support for root resources
      rootsListChanged: true, // Indicates support for notifications on root list changes
      sampling: true, // Indicates support for sampling if applicable
    ),
  );

  // --- SSE Transport Configuration ---
  // This is the core change: using SseTransport instead of StdioTransport.
  // The SseTransport connects to an MCP server over HTTP using Server-Sent Events.
  // IMPORTANT: Replace 'http://localhost:YOUR_SSE_PORT/mcp' with your actual SSE server endpoint.
  final sseServerUri = Uri.parse('http://192.168.0.98:8052/sse'); // Placeholder URI
  print('[SSE Client] SSE Server URI: $sseServerUri (NEEDS CONFIGURATION)');
  _log('[SSE Client] SSE Server URI: $sseServerUri (NEEDS CONFIGURATION)', logSink);

  // Attempt to create an SseTransport.
  // This assumes SseTransport has a constructor like `SseTransport(Uri)`.
  // You might need to adjust this based on the actual mcp_client package API.
  // For example, it might be `McpClient.createSseTransport(...)` or similar.
  // For now, let's assume a direct instantiation or a factory method.
  // We'll use a placeholder for actual SseTransport creation.
  // In a real scenario, you'd import and use the correct SseTransport class from mcp_client.
  // For this example, we'll simulate its creation.
  // final transport = SseTransport(sseServerUri); // Hypothetical direct instantiation
  // Let's assume there's a factory like this, similar to StdioTransport:
  // final transport = await McpClient.createSseTransport(uri: sseServerUri); // More likely pattern

  // For the purpose of this example, as I cannot know the exact factory method without package details,
  // I will structure it as if `SseTransport` is directly constructible or has a simple factory.
  // The actual implementation will depend on the `mcp_client` package's API for SSE.
  // We will proceed with a conceptual `SseTransport` that needs to be replaced with the actual one.

  // Placeholder for SseTransport - replace with actual mcp_client SseTransport
  // late final McpTransport transport;
  try {
    // This is a conceptual representation. Replace with actual SseTransport instantiation.
    // For example, if SseTransport is in `package:mcp_client/src/sse_transport.dart`
    // and has a constructor `SseTransport(this.uri)`
    // transport = SseTransport(uri: sseServerUri); // This is a guess.
    // Or if there's a factory:
    // transport = await McpClient.createSseTransport(uri: sseServerUri);

    // Given the file structure, there's `lib/core/mcp_communication/connectors/sse_connector.dart`
    // It likely contains `SseConnector` which might be the transport or used by it.
    // Let's assume `McpClient.createSseTransport` exists or `SseTransport` can be directly used.
    // For now, we'll use a generic placeholder and print a warning.
    print('[SSE Client] Attempting to create SseTransport using McpClient.createSseTransport...');
    _log('[SSE Client] Attempting to create SseTransport using McpClient.createSseTransport...', logSink);

    // Use the factory method from McpClient to create the SSE transport.
    // This assumes the method exists and has a signature like:
    // static Future<McpTransport> createSseTransport({required Uri uri, Map<String, String>? headers})
    // The headers parameter is often useful for SSE authentication or custom metadata.
    final transport = await McpClient.createSseTransport(
        serverUrl: sseServerUri.toString(), // Convert Uri to String for serverUrl
        // Optional: Add headers if needed for your SSE server
        // headers: {'Authorization': 'Bearer YOUR_TOKEN'},
    );
    print('[SSE Client] SseTransport created successfully.');
    _log('[SSE Client] SseTransport created successfully.', logSink);

    _log('[SSE Client] Attempting to connect to SSE MCP server at $sseServerUri...', logSink);
    print('[SSE Client] Attempting to connect to SSE MCP server at $sseServerUri...');

    // --- Connection and Event Handling ---
    try {
      Completer<void> connectionEstablishedCompleter = Completer<void>();

      // Register core event handlers BEFORE connecting
      client.onConnect.listen((ServerInfo serverInfo) {
        _log('[SSE Client] onConnect: Connected to server: ${serverInfo.name} v${serverInfo.version} (MCP v${serverInfo.protocolVersion})', logSink);
        print('[SSE Client] onConnect: Connected to server: ${serverInfo.name} v${serverInfo.version} (MCP v${serverInfo.protocolVersion})');

        // Log the capabilities object itself to understand its structure
        _log('[SSE Client] ServerInfo.capabilities runtimeType: ${serverInfo.capabilities?.runtimeType}', logSink);
        print('[SSE Client] ServerInfo.capabilities runtimeType: ${serverInfo.capabilities?.runtimeType}');
        _log('[SSE Client] ServerInfo.capabilities toString: ${serverInfo.capabilities?.toString()}', logSink);
        print('[SSE Client] ServerInfo.capabilities toString: ${serverInfo.capabilities?.toString()}');

        // Defensive check before casting and accessing
        List<dynamic> tools = [];
        if (serverInfo.capabilities?.tools is List) {
          tools = (serverInfo.capabilities?.tools as List<dynamic>?) ?? [];
        } else {
          _log('[SSE Client] Warning: serverInfo.capabilities.tools is NOT a List. Actual type: ${serverInfo.capabilities?.tools?.runtimeType}, value: ${serverInfo.capabilities?.tools}', logSink);
          print('[SSE Client] Warning: serverInfo.capabilities.tools is NOT a List. Actual type: ${serverInfo.capabilities?.tools?.runtimeType}, value: ${serverInfo.capabilities?.tools}');
        }
        
        List<dynamic> resources = [];
        if (serverInfo.capabilities?.resources is List) {
          resources = (serverInfo.capabilities?.resources as List<dynamic>?) ?? [];
        } else {
          _log('[SSE Client] Warning: serverInfo.capabilities.resources is NOT a List. Actual type: ${serverInfo.capabilities?.resources?.runtimeType}, value: ${serverInfo.capabilities?.resources}', logSink);
          print('[SSE Client] Warning: serverInfo.capabilities.resources is NOT a List. Actual type: ${serverInfo.capabilities?.resources?.runtimeType}, value: ${serverInfo.capabilities?.resources}');
        }

        _log('\n--- [SSE Client] Tools from ServerInfo (${tools.length}) ---', logSink);
        print('\n--- [SSE Client] Tools from ServerInfo (${tools.length}) ---');
        if (tools.isEmpty) {
          _log('[SSE Client] No tools listed in ServerInfo capabilities.', logSink);
          print('[SSE Client] No tools listed in ServerInfo capabilities.');
        } else {
          for (final dynamic toolDynamic in tools) {
            if (toolDynamic is Map<String, dynamic>) {
              final tool = toolDynamic; // Now tool is Map<String, dynamic>
              final toolInfo = '[SSE Client] ServerInfo Tool: ${tool['name']} - ${tool['description']} (Input Schema: ${tool['inputSchema']})';
              _log(toolInfo, logSink);
              print(toolInfo);
            } else {
              _log('[SSE Client] Warning: tool item in ServerInfo.capabilities.tools is not a Map: $toolDynamic', logSink);
            }
          }
        }

        _log('\n--- [SSE Client] Resources from ServerInfo (${resources.length}) ---', logSink);
        print('\n--- [SSE Client] Resources from ServerInfo (${resources.length}) ---');
        if (resources.isEmpty) {
          _log('[SSE Client] No resources listed in ServerInfo capabilities.', logSink);
          print('[SSE Client] No resources listed in ServerInfo capabilities.');
        } else {
          for (final dynamic resourceDynamic in resources) {
             if (resourceDynamic is Map<String, dynamic>) {
              final resource = resourceDynamic; // Now resource is Map<String, dynamic>
              final resourceInfo = '[SSE Client] ServerInfo Resource: ${resource['name']} (URI: ${resource['uri']}, Type: ${resource['type']})';
              _log(resourceInfo, logSink);
              print(resourceInfo);
            } else {
              _log('[SSE Client] Warning: resource item in ServerInfo.capabilities.resources is not a Map: $resourceDynamic', logSink);
            }
          }
        }
        if (!connectionEstablishedCompleter.isCompleted) {
          connectionEstablishedCompleter.complete();
        }
      });

      client.onError.listen((McpError error) {
        _log('[SSE Client] onError: Received McpError: ${error.message}', logSink);
        print('[SSE Client] onError: Received McpError: ${error.message}');
        if (error is McpError) { // Already checked, but good for clarity
            String mcpErrorDetails = '[SSE Client] McpError details from onError: toString(): ${error.toString()}';
            _log(mcpErrorDetails, logSink);
            print(mcpErrorDetails);
        }
        if (!connectionEstablishedCompleter.isCompleted) {
          connectionEstablishedCompleter.completeError(error);
        }
      });

      client.onDisconnect.listen((DisconnectReason reason) {
        _log('[SSE Client] onDisconnect: Disconnected. Reason: ${reason.toString()}', logSink);
        print('[SSE Client] onDisconnect: Disconnected. Reason: ${reason.toString()}');
        if (!connectionEstablishedCompleter.isCompleted) {
          // If disconnect happens before onConnect, it's an error for the connection attempt.
          connectionEstablishedCompleter.completeError(StateError('Disconnected before connection was fully established. Reason: $reason'));
        }
      });
      
      // Register other notification handlers as before
      client.onToolsListChanged(() {
        _log('[SSE Client] Tools list has changed! (Received server notification)', logSink);
        print('[SSE Client] Event: Tools list changed.');
      });

      client.onResourcesListChanged(() {
        _log('[SSE Client] Resources list has changed! (Received server notification)', logSink);
        print('[SSE Client] Event: Resources list changed.');
      });

      client.onLogging((level, message, loggerName, data) {
        final logMessage = '[SSE Client] Server Log ($loggerName) [$level]: $message ${data != null ? jsonEncode(data) : ""}';
        _log(logMessage, logSink);
        print(logMessage);
      });

      // Connect to the server using the configured SSE transport.
      _log('[SSE Client] Attempting client.connect(transport)...', logSink);
      print('[SSE Client] Attempting client.connect(transport)...');
      await client.connect(transport); // This will trigger onConnect or onError
      _log('[SSE Client] client.connect() call completed. Waiting for onConnect/onError callback via completer...', logSink);
      print('[SSE Client] client.connect() call completed. Waiting for onConnect/onError callback via completer...');
      
      // Wait for the onConnect or onError to fire from the listeners above
      await connectionEstablishedCompleter.future;
      _log('[SSE Client] Connection completer finished. Assuming connection process is stable if no error.', logSink);
      print('[SSE Client] Connection completer finished. Assuming connection process is stable if no error.');


      // _log('[SSE Client] Adding a 2-second delay before proceeding with operations...', logSink);
      // print('[SSE Client] Adding a 2-second delay before proceeding with operations...');
      // await Future.delayed(Duration(seconds: 2));
      // _log('[SSE Client] Delay finished. Proceeding with operations.', logSink);
      // print('[SSE Client] Delay finished. Proceeding with operations.');

      _log('[SSE Client] Proceeding with explicit _listAvailableTools and _listAvailableResources calls.', logSink);
      print('[SSE Client] Proceeding with explicit _listAvailableTools and _listAvailableResources calls.');
      // --- Example Operations ---
      // These operations demonstrate interaction with the MCP server.

      await _listAvailableTools(client, logSink);
      _log('[SSE Client] POST-LIST-TOOLS: Finished _listAvailableTools. About to list resources.', logSink);
      print('[SSE Client] POST-LIST-TOOLS: Finished _listAvailableTools. About to list resources.');
      
      await _listAvailableResources(client, logSink);
      _log('[SSE Client] POST-LIST-RESOURCES: Finished _listAvailableResources.', logSink);
      print('[SSE Client] POST-LIST-RESOURCES: Finished _listAvailableResources.');

      // Example: Call a simple tool (e.g., an "echo" tool if the server supports it)
      // This helps verify that request-response over SSE is working.
      // For now, keep this commented to isolate listTools/listResources issues.
      // final echoToolName = 'echo';
      // bool echoToolExists = false;
      // try {
      //   echoToolExists = (await client.listTools()).any((tool) => tool['name'] == echoToolName);
      // } catch (e) {
      //    _log('[SSE Client] Error checking for echo tool during listTools(): $e', logSink);
      // }
      // if (echoToolExists) {
      //   await _callEchoTool(client, echoToolName, logSink);
      // } else {
      //   _log('\n[SSE Client] Tool "$echoToolName" not found or error listing tools. Skipping echo tool call example.', logSink);
      //   print('[SSE Client] Tool "$echoToolName" not found or error listing tools. Skipping echo tool call example.');
      // }

      // Example: Read a resource (if applicable and server provides resources)
      // Keep this commented for now.
      // final exampleResourceUri = 'mcp://example-server/status';
      // bool resourceExists = false;
      // try {
      //    resourceExists = (await client.listResources()).any((res) => res['uri'] == exampleResourceUri);
      // } catch (e) {
      //   _log('[SSE Client] Error checking for resource during listResources(): $e', logSink);
      // }
      // if (resourceExists) {
      //    await _readExampleResource(client, exampleResourceUri, logSink);
      // } else {
      //   _log('\n[SSE Client] Resource "$exampleResourceUri" not found or error listing resources. Skipping read resource example.', logSink);
      //   print('[SSE Client] Resource "$exampleResourceUri" not found or error listing resources. Skipping read resource example.');
      // }


      // Keep the client running for a bit to receive potential SSE events
      _log('\n[SSE Client] Client operations attempted. Waiting for a short duration (e.g., for 5 seconds)...', logSink);
      print('[SSE Client] Client operations attempted. Waiting for a short duration (e.g., for 5 seconds)...');
      await Future.delayed(Duration(seconds: 5));

      _log('\n[SSE Client] Observation period completed.', logSink);
      print('[SSE Client] Observation period completed.');

    } catch (e, s) {
      final errorMessage = '[SSE Client] Connection or operational error: $e';
      _log('$errorMessage\nStackTrace: $s', logSink);
      print('$errorMessage\nStackTrace: $s');
      if (e is McpError) {
        // Attempt to log e.message if available, and always e.toString()
        String mcpErrorDetails = '[SSE Client] McpError details in main: toString(): ${e.toString()}';
        // McpError might not have a public 'message' field, but it's common.
        // Let's try to access it defensively or rely on toString().
        // For now, toString() is the safest bet.
        // If e.message exists and is different, we might add it later.
        _log(mcpErrorDetails, logSink);
        print(mcpErrorDetails);
      }
    } finally {
      // --- Disconnection ---
      // Always ensure the client is disconnected to release resources.
      _log('[SSE Client] Disconnecting client...', logSink);
      print('[SSE Client] Attempting to disconnect SSE client...');
      client.disconnect(); // disconnect is likely synchronous (void)
      _log('[SSE Client] Client disconnected from SSE server.', logSink);
      print('[SSE Client] SSE client disconnected.');
    }
  } catch (e, s) {
    // Catch errors during transport creation itself
    final transportErrorMessage = '[SSE Client] Error creating SSE transport: $e';
    _log('$transportErrorMessage\nStackTrace: $s', logSink);
    print('$transportErrorMessage\nStackTrace: $s');
  } finally {
    // Log finished message BEFORE closing the sink
    _log('[SSE Client] SSE client example finished.', logSink); // This log might occur before onDisconnect logs if disconnect is also in finally
    print('[SSE Client] SSE client example finished.');

    _log('[SSE Client] Closing log file.', logSink);
    print('[SSE Client] Closing log file.');
    if (logSink != null) {
      await logSink.flush();
      await logSink.close();
      logSink = null; // Set to null after closing
    }
    // Exit the application (optional, depending on context)
    // In a Flutter app, you wouldn't typically call exit(0).
    // For a command-line test client, this is common.
    // exit(0); // Commented out as it might not be suitable for all Dart environments
  }
}

/// Helper function to list available tools from the server.
Future<void> _listAvailableTools(Client client, IOSink logSink) async { // Changed McpClient to Client
  _log('\n--- [SSE Client] Entering _listAvailableTools ---', logSink);
  print('\n--- [SSE Client] Entering _listAvailableTools ---');
  // Assuming 'client.isConnected' exists.
  final bool currentIsConnected = client.isConnected;
  _log('[SSE Client] Client status before listTools(): isConnected: $currentIsConnected', logSink);
  print('[SSE Client] Client status before listTools(): isConnected: $currentIsConnected');
  _log('[SSE Client] Attempting to call client.listTools()...', logSink);
  print('[SSE Client] Attempting to call client.listTools()...');
  try {
    final tools = await client.listTools();
    _log('[SSE Client] client.listTools() call completed.', logSink);
    print('[SSE Client] client.listTools() call completed.');
    if (tools.isEmpty) {
      _log('[SSE Client] No tools available from the server.', logSink);
      print('[SSE Client] No tools available.');
    } else {
      _log('[SSE Client] Found ${tools.length} tools:', logSink);
      print('[SSE Client] Found ${tools.length} tools:');
      for (final tool in tools) {
        final toolInfo = '[SSE Client] Tool: ${tool.name} - ${tool.description} (Input Schema: ${tool.inputSchema})';
        _log(toolInfo, logSink);
        print(toolInfo);
      }
    }
  } catch (e, s) {
    final errorMsg = '[SSE Client] Error listing tools: $e';
    _log('$errorMsg\nStackTrace: $s', logSink);
    print(errorMsg);
    if (e is McpError) {
      String mcpErrorDetails = '[SSE Client] McpError details in _listAvailableTools: toString(): ${e.toString()}';
      _log(mcpErrorDetails, logSink);
      print(mcpErrorDetails);
    }
  }
}

/// Helper function to list available resources from the server.
Future<void> _listAvailableResources(Client client, IOSink logSink) async { // Changed McpClient to Client
  _log('\n--- [SSE Client] Entering _listAvailableResources ---', logSink);
  print('\n--- [SSE Client] Entering _listAvailableResources ---');
  _log('[SSE Client] Attempting to call client.listResources()...', logSink);
  print('[SSE Client] Attempting to call client.listResources()...');
  try {
    final resources = await client.listResources();
    _log('[SSE Client] client.listResources() call completed.', logSink);
    print('[SSE Client] client.listResources() call completed.');
    if (resources.isEmpty) {
      _log('[SSE Client] No resources available from the server.', logSink);
      print('[SSE Client] No resources available.');
    } else {
      _log('[SSE Client] Found ${resources.length} resources:', logSink);
      print('[SSE Client] Found ${resources.length} resources:');
      for (final resource in resources) {
        final resourceInfo = '[SSE Client] Resource: ${resource.name} (URI: ${resource.uri})'; // Removed .type as it's not defined
        _log(resourceInfo, logSink);
        print(resourceInfo);
      }
    }
  } catch (e, s) {
    final errorMsg = '[SSE Client] Error listing resources: $e';
    _log('$errorMsg\nStackTrace: $s', logSink);
    print(errorMsg);
    if (e is McpError) {
      String mcpErrorDetails = '[SSE Client] McpError details in _listAvailableResources: toString(): ${e.toString()}';
      _log(mcpErrorDetails, logSink);
      print(mcpErrorDetails);
    }
  }
}

/// Helper function to call an "echo" tool (or any simple tool).
Future<void> _callEchoTool(Client client, String toolName, IOSink logSink) async { // Changed McpClient to Client
  _log('\n--- [SSE Client] Calling Tool: $toolName ---', logSink);
  print('\n--- [SSE Client] Calling Tool: $toolName ---');
  try {
    final payload = {'message': 'Hello from SSE Client!', 'timestamp': DateTime.now().toIso8601String()};
    _log('[SSE Client] Calling tool "$toolName" with payload: ${jsonEncode(payload)}', logSink);
    print('[SSE Client] Sending to tool "$toolName": ${jsonEncode(payload)}');

    final result = await client.callTool(toolName, payload);
    print('[SSE Client] Received from tool "$toolName" (raw): ${result.isError} ${result.content}');


    if (result.isError == true) {
      final errorContent = result.content.isNotEmpty ? (result.content.first as TextContent).text : "Unknown error structure";
      _log('[SSE Client] Error calling tool "$toolName": $errorContent', logSink);
      print('[SSE Client] Error calling tool "$toolName": $errorContent');
    } else {
      final responseText = result.content.isNotEmpty ? (result.content.first as TextContent).text : "Empty response";
      _log('[SSE Client] Tool "$toolName" response: $responseText', logSink);
      print('[SSE Client] Tool "$toolName" response: $responseText');
    }
  } catch (e, s) {
    final errorMsg = '[SSE Client] Error calling tool "$toolName": $e';
    _log('$errorMsg\nStackTrace: $s', logSink);
    print(errorMsg);
  }
}

/// Helper function to read an example resource.
Future<void> _readExampleResource(Client client, String resourceUri, IOSink logSink) async { // Changed McpClient to Client
  _log('\n--- [SSE Client] Reading Resource: $resourceUri ---', logSink);
  print('\n--- [SSE Client] Reading Resource: $resourceUri ---');
  try {
    _log('[SSE Client] Attempting to read resource: $resourceUri', logSink);
    print('[SSE Client] Attempting to read resource: $resourceUri');

    final resourceResult = await client.readResource(resourceUri);
    print('[SSE Client] Received from resource "$resourceUri" (raw): ${resourceResult.contents}');


    if (resourceResult.contents.isNotEmpty) {
      final content = resourceResult.contents.first;
      final contentText = content.text ?? "No text content";
      _log('[SSE Client] Resource "$resourceUri" content (first 200 chars): ${contentText.substring(0, contentText.length > 200 ? 200 : contentText.length)}...', logSink);
      print('[SSE Client] Resource "$resourceUri" content: $contentText');
    } else {
      _log('[SSE Client] No content returned from resource "$resourceUri".', logSink);
      print('[SSE Client] No content returned from resource "$resourceUri".');
    }
  } catch (e, s) {
    final errorMsg = '[SSE Client] Error reading resource "$resourceUri": $e';
    _log('$errorMsg\nStackTrace: $s', logSink);
    print(errorMsg);
  }
}


/// Logs messages to both a file (if provided) and using `debugPrint`.
/// `debugPrint` is preferred for console output during development.
void _log(String message, IOSink? logSink) { // Accept nullable IOSink
  // Log to debug console (visible in IDEs like VS Code, Android Studio)
  // debugPrint is from flutter/foundation.dart, good for Flutter apps.
  // For pure Dart CLI, print() or a dedicated logger might be used.
  // Since this is an example, debugPrint is fine.
  // Note: debugPrint might be throttled by the system if too many logs.
  // No prefix needed here as functions calling _log already add context.
  // debugPrint(message); // Already handled by callers

  // Log to stderr via the _logger instance (if still desired)
  _logger.debug(message);

  // Also log to the specified file sink if it's not null
  if (logSink != null) {
    try {
      logSink.writeln('${DateTime.now().toIso8601String()} - $message');
    } catch (e) {
      // This catch is a safeguard if the sink becomes unusable between the null check and writeln.
      // For example, if another part of the code closes it without setting our logSink variable to null.
      final consoleErrorMsg = 'Error writing to logSink in _log (already closed or error?): $e. Original message: $message';
      print(consoleErrorMsg); // Print to console as fallback
      _logger.warning(consoleErrorMsg); // Use 'warning' as a safer bet
    }
  }
}

// Note: The _PlaceholderSseTransport class has been removed as we are now
// attempting to use `McpClient.createSseTransport`.
// Ensure all necessary classes like McpSocketMessage, ServerHello, ServerCapabilities,
// McpException, TextContent are correctly imported from the mcp_client package,
// as they are used in notification handlers and result processing.