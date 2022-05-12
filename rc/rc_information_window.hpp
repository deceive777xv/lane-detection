#pragma once

#include <gtkmm/applicationwindow.h>
#include <gtkmm/box.h>
#include <gtkmm/boxlayout.h>
#include <gtkmm/button.h>
#include <gtkmm/entry.h>
#include <gtkmm/frame.h>
#include <gtkmm/label.h>

#include "rc_uart_manager.hpp"
#include "rc_connection.hpp"

class UartManager;
enum class ConnectionState;

class InformationWindow : public Gtk::ApplicationWindow {
	const int CONTAINER_MARGIN = 4;

	private:
		UartManager *uart_manager;

		Gtk::Box main_container;

		// The frame with connection info and
		// connect/disconnect buttons
		Gtk::Frame connection_frame;
		Gtk::Box connection_container;
		Gtk::Entry port_entry;
		Gtk::Button connect_button;

	public:
		sigc::signal<void(Glib::ustring)> connect_request_signal;
		sigc::signal<void()> disconnect_request_signal;

		InformationWindow(UartManager *uart_manager);

		// Application callbacks
		void on_connection_state_update(ConnectionState state);

		// UI callbacks
		void on_connect_request();
};

