import 'package:flutter/material.dart';

// Modelo de Mesa
class Mesa {
  final int numero;
  final bool reservada;
  const Mesa({required this.numero, required this.reservada});
}

// Pantalla de formulario de reserva
class FormularioReservaScreen extends StatelessWidget {
  final Mesa mesa;
  const FormularioReservaScreen({super.key, required this.mesa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reservar Mesa ${mesa.numero}')),
      body: Center(
        child: Text('Formulario de reserva para la mesa ${mesa.numero}'),
      ),
    );
  }
}

// Pantalla principal de mesas
class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  static const List<Mesa> mesas = [
    Mesa(numero: 1, reservada: true),
    Mesa(numero: 2, reservada: false),
    Mesa(numero: 3, reservada: false),
    Mesa(numero: 4, reservada: true),
    Mesa(numero: 5, reservada: false),
    Mesa(numero: 6, reservada: false),
    Mesa(numero: 7, reservada: true),
    Mesa(numero: 8, reservada: false),
    Mesa(numero: 9, reservada: false),
    Mesa(numero: 10, reservada: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesas disponibles')),
      body: ListView.builder(
        itemCount: mesas.length,
        itemBuilder: (context, index) {
          final mesa = mesas[index];
          return ListTile(
            title: Text('Mesa ${mesa.numero}'),
            subtitle: Text(mesa.reservada ? 'Reservada' : 'Disponible'),
            trailing: Icon(
              mesa.reservada ? Icons.lock : Icons.event_seat,
              color: mesa.reservada ? Colors.red : Colors.green,
            ),
            enabled: !mesa.reservada,
            onTap:
                mesa.reservada
                    ? null
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormularioReservaScreen(mesa: mesa),
                        ),
                      );
                    },
          );
        },
      ),
    );
  }
}
