use crate::core::input::InputState;
use crate::states::{GameState, InGameState};
use crate::types::Player;
use bevy::prelude::*;

pub struct PlayerControllerPlugin;

impl Plugin for PlayerControllerPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(OnEnter(GameState::InGame), spawn_player)
            // Используем FixedUpdate для стабильного расчёта движения без рывков
            .add_systems(FixedUpdate, move_player.run_if(in_state(InGameState::Playing)))
            .add_systems(OnExit(GameState::InGame), cleanup_player);
    }
}

#[derive(Component, Default)]
struct PlayerVelocity {
    velocity: Vec3,
}

fn spawn_player(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    commands.spawn((
        Player,
        PlayerVelocity::default(),
        Mesh3d(meshes.add(Cuboid::new(1.0, 2.0, 1.0))),
        MeshMaterial3d(materials.add(Color::srgb(1.0, 0.5, 0.0))),
        Transform::from_xyz(0.0, 1.0, 0.0),
    ));
}

fn move_player(
    input: Res<InputState>,
    // В FixedUpdate вместо time используем fixed_time
    fixed_time: Res<Time<Fixed>>,
    camera_query: Query<&Transform, (With<Camera3d>, Without<Player>)>,
    mut query: Query<(&mut Transform, &mut PlayerVelocity), With<Player>>,
) {
    let speed = 6.0;
    let acceleration = 15.0; // Чуть увеличим отзывчивость
    let rotation_speed = 20.0;

    let camera_transform = match camera_query.single() {
        Ok(cam) => cam,
        Err(_) => return,
    };

    let mut camera_forward = camera_transform.forward().as_vec3();
    camera_forward.y = 0.0;
    let camera_forward = camera_forward.normalize_or_zero();

    let mut camera_right = camera_transform.right().as_vec3();
    camera_right.y = 0.0;
    let camera_right = camera_right.normalize_or_zero();

    for (mut transform, mut vel) in &mut query {
        // Шаг фиксированного времени
        let dt = fixed_time.delta_secs();

        let target_dir = (camera_forward * input.move_dir.y + camera_right * input.move_dir.x)
            .normalize_or_zero();

        let target_velocity = target_dir * speed;

        // Плавный разгон/торможение
        vel.velocity = vel.velocity.lerp(target_velocity, acceleration * dt);

        if vel.velocity.length_squared() < 0.0001 && target_dir == Vec3::ZERO {
            vel.velocity = Vec3::ZERO;
        }

        transform.translation += vel.velocity * dt;

        if target_dir != Vec3::ZERO {
            let look_target = transform.translation + target_dir;
            let current_pos = transform.translation;

            let mut target_rotation = Transform::from_translation(current_pos);
            target_rotation.look_at(look_target, Vec3::Y);

            transform.rotation = transform.rotation.slerp(target_rotation.rotation, rotation_speed * dt);
        }
    }
}

fn cleanup_player(mut commands: Commands, query: Query<Entity, With<Player>>) {
    for entity in &query {
        commands.entity(entity).despawn();
    }
}
