/**
 * Organization Admin Dashboard Example
 *
 * Complete admin interface for managing organization members, roles, and settings.
 *
 * Features:
 * - Member list with role management
 * - Pending invitations display
 * - Role assignment interface
 * - Organization settings
 * - Permission-based access control
 *
 * Required permissions: MEMBERS_MANAGE or higher
 */

'use client';

import { useOrganization, useOrganizationList, useUser } from '@clerk/nextjs';
import { useState, useEffect } from 'react';
import {
  hasPermission,
  hasMinimumRole,
  PERMISSIONS,
  ROLES,
  getRoleName,
  getRoleColor,
  getAllRolesInfo,
  type Role,
} from '@/lib/rbac';

/**
 * Organization Admin Dashboard
 */
export function OrganizationAdminDashboard() {
  const { organization, membership, memberships, invitations } = useOrganization({
    memberships: {
      infinite: true,
      pageSize: 20,
    },
    invitations: {
      infinite: true,
      pageSize: 20,
    },
  });

  if (!organization || !membership) {
    return <div>Loading...</div>;
  }

  // Check if user has permission to manage members
  const canManageMembers = hasPermission(membership.role, PERMISSIONS.MEMBERS_MANAGE);
  const canRemoveMembers = hasPermission(membership.role, PERMISSIONS.MEMBERS_REMOVE);
  const canInviteMembers = hasPermission(membership.role, PERMISSIONS.MEMBERS_INVITE);

  if (!canManageMembers) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <h2 className="text-xl font-semibold text-red-800 mb-2">Access Denied</h2>
          <p className="text-red-600">
            You don't have permission to manage organization members.
            Required permission: MEMBERS_MANAGE
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Organization Settings</h1>
        <p className="text-gray-500 mt-1">{organization.name}</p>
      </div>

      {/* Tabs */}
      <div className="mb-6">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button className="border-b-2 border-blue-500 py-4 px-1 text-sm font-medium text-blue-600">
              Members
            </button>
            <button className="border-transparent py-4 px-1 text-sm font-medium text-gray-500 hover:text-gray-700 hover:border-gray-300">
              Invitations
            </button>
            <button className="border-transparent py-4 px-1 text-sm font-medium text-gray-500 hover:text-gray-700 hover:border-gray-300">
              Settings
            </button>
          </nav>
        </div>
      </div>

      {/* Invite Member Section */}
      {canInviteMembers && (
        <div className="mb-8">
          <InviteMemberForm organizationId={organization.id} />
        </div>
      )}

      {/* Members List */}
      <div className="bg-white rounded-lg border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold">Members ({memberships?.count || 0})</h2>
        </div>

        <div className="divide-y divide-gray-200">
          {memberships?.data?.map((member) => (
            <MemberRow
              key={member.id}
              member={member}
              organization={organization}
              currentUserRole={membership.role}
              canRemove={canRemoveMembers}
            />
          ))}
        </div>
      </div>

      {/* Pending Invitations */}
      {invitations?.data && invitations.data.length > 0 && (
        <div className="mt-8 bg-white rounded-lg border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold">
              Pending Invitations ({invitations.count})
            </h2>
          </div>

          <div className="divide-y divide-gray-200">
            {invitations.data.map((invitation) => (
              <InvitationRow
                key={invitation.id}
                invitation={invitation}
                organization={organization}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * Invite Member Form
 */
function InviteMemberForm({ organizationId }: { organizationId: string }) {
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<Role>(ROLES.MEMBER);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { organization } = useOrganization();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email) return;

    setIsSubmitting(true);

    try {
      await organization?.inviteMember({
        emailAddress: email,
        role: role,
      });

      // Reset form
      setEmail('');
      setRole(ROLES.MEMBER);

      alert('Invitation sent successfully!');
    } catch (error) {
      console.error('Error inviting member:', error);
      alert('Failed to send invitation. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const availableRoles = getAllRolesInfo();

  return (
    <form onSubmit={handleSubmit} className="bg-blue-50 rounded-lg p-6">
      <h3 className="text-lg font-semibold mb-4">Invite New Member</h3>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="md:col-span-2">
          <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
            Email Address
          </label>
          <input
            type="email"
            id="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="member@example.com"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            required
          />
        </div>

        <div>
          <label htmlFor="role" className="block text-sm font-medium text-gray-700 mb-2">
            Role
          </label>
          <select
            id="role"
            value={role}
            onChange={(e) => setRole(e.target.value as Role)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            {availableRoles.map((roleInfo) => (
              <option key={roleInfo.role} value={roleInfo.role}>
                {roleInfo.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <button
        type="submit"
        disabled={isSubmitting || !email}
        className="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
      >
        {isSubmitting ? 'Sending...' : 'Send Invitation'}
      </button>
    </form>
  );
}

/**
 * Member Row Component
 */
function MemberRow({
  member,
  organization,
  currentUserRole,
  canRemove,
}: {
  member: any;
  organization: any;
  currentUserRole: string;
  canRemove: boolean;
}) {
  const [isChangingRole, setIsChangingRole] = useState(false);
  const [selectedRole, setSelectedRole] = useState<Role>(member.role);
  const { user } = useUser();

  const isCurrentUser = member.publicUserData.userId === user?.id;
  const canChangeRole = hasMinimumRole(currentUserRole, ROLES.ADMIN) && !isCurrentUser;

  const handleRoleChange = async () => {
    if (selectedRole === member.role) {
      setIsChangingRole(false);
      return;
    }

    try {
      await organization.updateMember({
        userId: member.publicUserData.userId,
        role: selectedRole,
      });

      alert('Role updated successfully!');
      setIsChangingRole(false);
    } catch (error) {
      console.error('Error updating role:', error);
      alert('Failed to update role. Please try again.');
      setSelectedRole(member.role);
    }
  };

  const handleRemoveMember = async () => {
    if (!confirm(`Remove ${member.publicUserData.identifier} from the organization?`)) {
      return;
    }

    try {
      await organization.removeMember(member.publicUserData.userId);
      alert('Member removed successfully!');
    } catch (error) {
      console.error('Error removing member:', error);
      alert('Failed to remove member. Please try again.');
    }
  };

  return (
    <div className="px-6 py-4 flex items-center justify-between">
      <div className="flex items-center gap-4 flex-1">
        {/* Avatar */}
        <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-semibold">
          {member.publicUserData.firstName?.charAt(0) || 'U'}
        </div>

        {/* Member Info */}
        <div>
          <p className="font-medium text-gray-900">
            {member.publicUserData.firstName} {member.publicUserData.lastName}
            {isCurrentUser && (
              <span className="ml-2 text-xs text-gray-500">(You)</span>
            )}
          </p>
          <p className="text-sm text-gray-500">{member.publicUserData.identifier}</p>
        </div>
      </div>

      {/* Role Badge/Selector */}
      <div className="flex items-center gap-3">
        {isChangingRole ? (
          <div className="flex items-center gap-2">
            <select
              value={selectedRole}
              onChange={(e) => setSelectedRole(e.target.value as Role)}
              className="px-3 py-1 border border-gray-300 rounded-lg text-sm"
            >
              {getAllRolesInfo().map((roleInfo) => (
                <option key={roleInfo.role} value={roleInfo.role}>
                  {roleInfo.name}
                </option>
              ))}
            </select>
            <button
              onClick={handleRoleChange}
              className="px-3 py-1 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700"
            >
              Save
            </button>
            <button
              onClick={() => {
                setIsChangingRole(false);
                setSelectedRole(member.role);
              }}
              className="px-3 py-1 border border-gray-300 rounded-lg text-sm hover:bg-gray-50"
            >
              Cancel
            </button>
          </div>
        ) : (
          <>
            <span
              className="px-3 py-1 rounded-full text-sm font-medium"
              style={{
                backgroundColor: `${getRoleColor(member.role)}20`,
                color: getRoleColor(member.role),
              }}
            >
              {getRoleName(member.role)}
            </span>

            {canChangeRole && (
              <button
                onClick={() => setIsChangingRole(true)}
                className="p-2 hover:bg-gray-100 rounded"
                aria-label="Change role"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
              </button>
            )}
          </>
        )}

        {/* Remove Button */}
        {canRemove && !isCurrentUser && (
          <button
            onClick={handleRemoveMember}
            className="p-2 hover:bg-red-100 rounded text-red-600"
            aria-label="Remove member"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </button>
        )}
      </div>
    </div>
  );
}

/**
 * Invitation Row Component
 */
function InvitationRow({ invitation, organization }: { invitation: any; organization: any }) {
  const handleRevoke = async () => {
    if (!confirm(`Revoke invitation to ${invitation.emailAddress}?`)) {
      return;
    }

    try {
      await organization.revokeInvitation(invitation.id);
      alert('Invitation revoked successfully!');
    } catch (error) {
      console.error('Error revoking invitation:', error);
      alert('Failed to revoke invitation. Please try again.');
    }
  };

  return (
    <div className="px-6 py-4 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <div className="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-gray-600">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
            />
          </svg>
        </div>

        <div>
          <p className="font-medium text-gray-900">{invitation.emailAddress}</p>
          <p className="text-sm text-gray-500">Invited • Pending acceptance</p>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <span className="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium">
          {getRoleName(invitation.role)}
        </span>

        <button
          onClick={handleRevoke}
          className="px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg"
        >
          Revoke
        </button>
      </div>
    </div>
  );
}
