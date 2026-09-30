use crate::states::{GameState, InGameState};
use crate::types::{CameraRig, GameSettings, Player};
use bevy::input::mouse::MouseMotion;
use bevy::prelude::*;
use bevy::window::{CursorGrabMode, CursorOptions, PrimaryWindow};

pub struct CameraPlugin;

impl Plugin for CameraPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(OnEnter(GameState::InGame), spawn_camera_rig)
            .add_systems(
                Update,
                (
                    grab_cursor_on_click,
                    orbit_camera.run_if(in_state(InGameState::Playing)),
                    follow_player.run_if(in_state(InGameState::Playing)),
                ),
            )
            .add_systems(OnExit(GameState::InGame), cleanup_camera_rig);
    }
}

/// Спавним риг (позиция «плеча») и камеру как его ребёнка.
/// Позиция рига пересчитывается каждый кадр системой follow_player.
fn spawn_camera_rig(mut commands: Commands) {
    let rig = commands
        .spawn((
            CameraRig::default(),
            Transform::from_xyz(0.0, 1.6, 0.0),
            Visibility::default(),
        ))
        .id();

    commands.entity(rig).with_children(|parent| {
        parent.spawn((Camera3d::default(), Transform::from_xyz(0.0, 0.0, 0.0)));
    });
}

fn grab_cursor_on_click(
    mouse_buttons: Res<ButtonInput<MouseButton>>,
    mut cursor: Query<&mut CursorOptions, With<PrimaryWindow>>,
) {
    if mouse_buttons.just_pressed(MouseButton::Left) {
        if let Ok(mut options) = cursor.single_mut() {
            options.grab_mode = CursorGrabMode::Locked;
            options.visible = false;
        }
    }
}

fn orbit_camera(
    mut mouse_motion: MessageReader<MouseMotion>,
    settings: Res<GameSettings>,
    mut rig_query: Query<(&mut CameraRig, &Children)>,
    mut camera_query: Query<&mut Transform, (With<Camera3d>, Without<CameraRig>)>,
) {
    let mut delta = Vec2::ZERO;
    for ev in mouse_motion.read() {
        delta += ev.delta;
    }
    if delta == Vec2::ZERO {
        return;
    }

    for (mut rig, children) in &mut rig_query {
        rig.yaw -= delta.x * settings.mouse_sensitivity;
        rig.pitch -= delta.y * settings.mouse_sensitivity;
        rig.pitch = rig.pitch.clamp(rig.pitch_min, rig.pitch_max);

        let rotation = Quat::from_euler(EulerRot::YXZ, rig.yaw, rig.pitch, 0.0);
        let offset = rotation * Vec3::new(0.0, 0.0, rig.distance);

        for &child in children {
            if let Ok(mut cam_transform) = camera_query.get_mut(child) {
                cam_transform.translation = offset;
                cam_transform.rotation = rotation;
            }
        }
    }
}

/// Каждый кадр ставит риг в позицию игрока + высота глаз.
/// Без сглаживания — просто прилипание.
fn follow_player(
    player_query: Query<&Transform, (With<Player>, Without<CameraRig>)>,
    mut rig_query: Query<&mut Transform, With<CameraRig>>,
) {
    let Ok(player_transform) = player_query.single() else {
        return;
    };
    let eye_height = 1.6;
    let target = player_transform.translation + Vec3::new(0.0, eye_height, 0.0);
    for mut rig_transform in &mut rig_query {
        rig_transform.translation = target;
    }
}

fn cleanup_camera_rig(mut commands: Commands, query: Query<Entity, With<CameraRig>>) {
    for entity in &query {
        commands.entity(entity).despawn();
    }
}
